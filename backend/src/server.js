import { createHash, randomUUID } from "node:crypto";

import agoraToken from "agora-token";
import {
  AppStoreServerAPIClient,
  Environment as AppleEnvironment,
} from "@apple/app-store-server-library";
import express from "express";
import { applicationDefault, cert, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { google } from "googleapis";
import OpenAI, { toFile } from "openai";
import Stripe from "stripe";
import { requireLiveEconomy, calculateGiftSettlement, calculatePurchaseCredit } from "./economy_policy.js";
import {registerWalletRoutes} from "./wallet_routes.js";
import {registerChatRoutes} from "./chat_routes.js";
import {chatIdFor, assertChatMembership} from "./chat_membership.js";
import {reverseVerifiedWebPurchase} from "./payment_reversals.js";
import {validateQuizDraft, quizWinners} from "./quiz_policy.js";
import {roomTaskSpec, advanceRoomLevel, roomLevelFromXp} from "./room_task_policy.js";
import {privateWalletRef, requirePrivateWallet} from "./wallet_store.js";

const { RtcRole, RtcTokenBuilder } = agoraToken;

const firebaseProjectId = (
  process.env.FIREBASE_PROJECT_ID ||
  process.env.GOOGLE_CLOUD_PROJECT ||
  ""
).trim();
if (process.env.NODE_ENV === "production" && !firebaseProjectId) {
  throw new Error("Cannot start production backend: missing FIREBASE_PROJECT_ID");
}
// Agora credentials are required only by /agora/token. Production deployments
// may intentionally keep the certificate solely in the existing Cloudflare
// token Worker and use this service for Teacher AI, gifts, wallet and stores.

if (getApps().length === 0) {
  const rawServiceAccount = String(
    process.env.FIREBASE_SERVICE_ACCOUNT_JSON || "",
  ).trim();
  let credential;
  if (rawServiceAccount) {
    let serviceAccount;
    try {
      serviceAccount = JSON.parse(rawServiceAccount);
    } catch {
      throw new Error(
        "FIREBASE_SERVICE_ACCOUNT_JSON must contain valid JSON.",
      );
    }
    credential = cert(serviceAccount);
  } else {
    credential = applicationDefault();
  }
  initializeApp({
    credential,
    ...(firebaseProjectId ? {projectId: firebaseProjectId} : {}),
  });
}

const auth = getAuth();
const db = getFirestore();

const app = express();
app.disable("x-powered-by");

const stripeSecret = String(process.env.STRIPE_SECRET_KEY || "").trim();
const stripeWebhookSecret = String(process.env.STRIPE_WEBHOOK_SECRET || "").trim();
const stripe = stripeSecret ? new Stripe(stripeSecret) : null;

/**
 * Web-only card checkout webhook: raw body and Stripe signature are mandatory.
 * No Flutter mobile view or payment UI may expose this route as an alternate
 * checkout unless store-specific eligibility has been independently approved.
 */
app.post("/web/stripe/webhook", express.raw({type: "application/json"}),
  async (req, res, next) => {
    if (!stripe || !stripeWebhookSecret) {
      return res.status(503).json({error: "Stripe webhook not configured."});
    }
    let event;
    try {
      event = stripe.webhooks.constructEvent(
        req.body, req.headers["stripe-signature"], stripeWebhookSecret,
      );
    } catch {
      return res.status(400).send("Invalid Stripe signature.");
    }
    if (["charge.refunded", "charge.dispute.created"].includes(event.type)) {
      try {
        const reversal = await reverseVerifiedWebPurchase({stripe, db, event});
        return res.json({received: true, reversal});
      } catch (error) {
        // Stripe must retry if reconciliation or a security hold failed.
        return next(error);
      }
    }
    if (!["checkout.session.completed",
      "checkout.session.async_payment_succeeded"].includes(event.type)) {
      return res.json({received: true});
    }
    const session = event.data.object;
    if (session.mode !== "payment" || session.payment_status !== "paid") {
      return res.json({received: true, credited: false});
    }
    try {
      const userId = String(session.client_reference_id || "");
      const catalogId = String(session.metadata?.catalogId || "");
      if (!userId || !catalogId) {
        throw new Error("Signed session is missing purchase metadata.");
      }
      const productSnap = await db.collection("coin_products").doc(catalogId).get();
      const product = productSnap.data() || {};
      const policy = requireLiveEconomy(
        (await db.doc("economy_config/current").get()).data(),
      );
      const units = Number(product.coins);
      const expectedCents = Math.round(Number(product.priceUsd) * 100);
      if (!productSnap.exists || product.active !== true ||
          !product.webPriceId || !Number.isSafeInteger(units) ||
          units <= 0 || !Number.isSafeInteger(expectedCents) ||
          expectedCents <= 0 || session.currency !== "usd" ||
          session.amount_total !== expectedCents) {
        throw new Error("Stripe payment does not match approved catalog.");
      }
      const lines = await stripe.checkout.sessions.listLineItems(session.id);
      if (lines.data.length !== 1 || lines.has_more ||
          lines.data[0].price?.id !== product.webPriceId ||
          lines.data[0].quantity !== 1) {
        throw new Error("Stripe line items do not match approved catalog.");
      }
      const credit = await creditVerifiedCoins({
        userId, platform: "web", receiptId: session.id,
        productId: product.webPriceId, catalogId,
        coins: units,
        purchasedAt: Date.now(),
      });
      res.json({received: true, credited: !credit.alreadyCredited});
    } catch (error) {
      // Return non-2xx so Stripe can safely redeliver the SAME session.
      next(error);
    }
  },
);

app.use(express.json({ limit: "32kb" }));

const port = Number(process.env.PORT || 8080);
const agoraAppId = (process.env.AGORA_APP_ID || "").trim();
const agoraCertificate = (process.env.AGORA_APP_CERTIFICATE || "").trim();
const openAiKey = (process.env.OPENAI_API_KEY || "").trim();
const teacherModel = (process.env.OPENAI_TEACHER_MODEL || "").trim();
const transcribeModel = (
  process.env.OPENAI_TRANSCRIBE_MODEL || "gpt-4o-mini-transcribe"
).trim();

const privilegedAccounts = new Map([
  ["ahmedabdalkarim19@gmail.com", {
    role: "super_admin",
    vipTier: "gold",
  }],
]);

const adminPermissions = [
  "view_visitors",
  "manage_rooms",
  "enter_private_rooms",
  "manage_vip",
  "manage_store",
  "manage_moderators",
  "send_coins",
  "change_country",
];

const androidPackageName =
  (process.env.ANDROID_PACKAGE_NAME || "com.worldvoice.app").trim();
const iosBundleId =
  (process.env.IOS_BUNDLE_ID || "com.worldvoice.worldvoice").trim();

const appleIapKeyId = (process.env.APPLE_IAP_KEY_ID || "").trim();
const appleIapIssuerId = (process.env.APPLE_IAP_ISSUER_ID || "").trim();
const appleIapPrivateKey = (process.env.APPLE_IAP_PRIVATE_KEY || "")
  .replace(/\\n/g, "\n")
  .trim();

const openai = openAiKey ? new OpenAI({ apiKey: openAiKey }) : null;

const googlePlayAuth = new google.auth.GoogleAuth({
  scopes: ["https://www.googleapis.com/auth/androidpublisher"],
});

function requireEnv(value, name) {
  if (!value) {
    const error = new Error(`Missing server environment variable: ${name}`);
    error.status = 503;
    throw error;
  }
  return value;
}

function agoraUidForFirebaseUid(firebaseUid) {
  const digest = createHash("sha256").update(firebaseUid).digest();
  const value = digest.readUInt32BE(0);
  return value === 0 ? 1 : value;
}

function bearerToken(req) {
  const value = String(req.headers.authorization || "");
  if (!value.startsWith("Bearer ")) return "";
  return value.slice("Bearer ".length).trim();
}

async function authenticatedUser(req) {
  const token = bearerToken(req);
  if (!token) {
    const error = new Error("Missing Firebase authorization token.");
    error.status = 401;
    throw error;
  }

  try {
    return await auth.verifyIdToken(token, true);
  } catch (cause) {
    // Keep secrets and raw bearer tokens out of server logs.
    const code = String(cause?.code || "unknown");
    console.error("Firebase authorization failed:", code);
    const sessionErrors = new Set([
      "auth/id-token-expired",
      "auth/id-token-revoked",
      "auth/invalid-id-token",
      "auth/argument-error",
      "auth/user-disabled",
      "auth/user-not-found",
    ]);
    const error = new Error(sessionErrors.has(code)
      ? "Your Firebase login has expired. Sign in again."
      : "Firebase server authentication needs administrator attention.");
    error.status = sessionErrors.has(code) ? 401 : 503;
    throw error;
  }
}

app.post("/account/sync-entitlements", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);
    const email = String(user.email || "").trim().toLowerCase();
    const privileged = privilegedAccounts.get(email);

    if (!privileged) {
      return res.json({ok: true, privileged: false});
    }

    const vipExpiresAt = Timestamp.fromDate(
      new Date("2099-12-31T23:59:59.000Z"),
    );
    const profileRef = db.collection("users").doc(user.uid);
    const adminRef = db.collection("admins").doc(user.uid);
    const batch = db.batch();

    batch.set(profileRef, {
      isVip: true,
      vipExpiresAt,
      vipSource: "worldvoice_admin_allowlist",
      vipUpdatedAt: FieldValue.serverTimestamp(),
      isAdmin: true,
      adminSource: "worldvoice_admin_allowlist",
      adminUpdatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    batch.set(adminRef, {
      uid: user.uid,
      email,
      role: privileged.role,
      permissions: adminPermissions,
      active: true,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    await batch.commit();
    return res.json({
      ok: true,
      privileged: true,
      isAdmin: true,
      isVip: true,
      role: privileged.role,
    });
  } catch (error) {
    next(error);
  }
});

function validChannelName(value) {
  return (
    typeof value === "string" &&
    value.length > 0 &&
    value.length < 64 &&
    /^[A-Za-z0-9_]+$/.test(value)
  );
}

function isStageRole(role) {
  return ["host", "coHost", "speaker", "vipSeat"].includes(role);
}

function decodeJwsPayload(value) {
  if (typeof value !== "string") return null;
  const parts = value.split(".");
  if (parts.length !== 3) return null;
  try {
    return JSON.parse(Buffer.from(parts[1], "base64url").toString("utf8"));
  } catch {
    return null;
  }
}

async function coinProductFor(platform, productId) {
  const field = platform === "android" ? "androidProductId" : "iosProductId";
  const snapshot = await db
    .collection("coin_products")
    .where(field, "==", productId)
    .limit(1)
    .get();

  if (snapshot.empty) {
    const error = new Error("Coin product is not configured.");
    error.status = 404;
    throw error;
  }

  const product = snapshot.docs[0].data() || {};
  const coins = Number(product.coins);
  if (product.active !== true || !Number.isInteger(coins) || coins <= 0) {
    const error = new Error("Coin product is not active.");
    error.status = 409;
    throw error;
  }

  return {
    catalogId: snapshot.docs[0].id,
    coins,
  };
}

async function verifyGooglePlayPurchase(productId, purchaseToken) {
  if (!purchaseToken) {
    const error = new Error("Missing Google Play purchase token.");
    error.status = 400;
    throw error;
  }

  const androidPublisher = google.androidpublisher({
    version: "v3",
    auth: googlePlayAuth,
  });

  const response = await androidPublisher.purchases.products.get({
    packageName: androidPackageName,
    productId,
    token: purchaseToken,
  });

  const purchase = response.data || {};
  if (Number(purchase.purchaseState) !== 0) {
    const error = new Error("Google Play purchase is not completed.");
    error.status = 409;
    throw error;
  }

  return {
    receiptId: String(purchase.orderId || purchaseToken),
    purchasedAt: Number(purchase.purchaseTimeMillis || 0),
  };
}

function appleApiClient(environment) {
  requireEnv(appleIapPrivateKey, "APPLE_IAP_PRIVATE_KEY");
  requireEnv(appleIapKeyId, "APPLE_IAP_KEY_ID");
  requireEnv(appleIapIssuerId, "APPLE_IAP_ISSUER_ID");

  return new AppStoreServerAPIClient(
    appleIapPrivateKey,
    appleIapKeyId,
    appleIapIssuerId,
    iosBundleId,
    environment,
  );
}

async function fetchAppleTransaction(transactionId, environmentHint) {
  const environments =
    String(environmentHint || "").toLowerCase() === "sandbox"
      ? [AppleEnvironment.SANDBOX, AppleEnvironment.PRODUCTION]
      : [AppleEnvironment.PRODUCTION, AppleEnvironment.SANDBOX];

  let lastError;
  for (const environment of environments) {
    try {
      const response = await appleApiClient(environment).getTransactionInfo(
        transactionId,
      );
      const signed = response.signedTransactionInfo;
      const payload = decodeJwsPayload(signed);
      if (!payload) {
        const error = new Error("Apple returned invalid transaction data.");
        error.status = 502;
        throw error;
      }
      return payload;
    } catch (error) {
      lastError = error;
    }
  }

  throw lastError ?? new Error("Apple transaction could not be verified.");
}

async function creditVerifiedCoins({
  userId, platform, receiptId, productId, catalogId, coins, purchasedAt,
}) {
  // The receipt key is stable across retries and duplicated Stripe events.
  const receiptKey = createHash("sha256")
    .update(`${platform}:${receiptId}`).digest("hex");
  const receiptRef = db.collection("iap_receipts").doc(receiptKey);
  const userRef = db.collection("users").doc(userId);
  const walletRef = privateWalletRef(userRef);
  const configRef = db.doc("economy_config/current");
  const productRef = db.collection("coin_products").doc(catalogId);
  const day = new Date().toISOString().slice(0, 10);
  const dailyRef = userRef.collection("economy_daily").doc(day);
  return db.runTransaction(async tx => {
    // Read all snapshots BEFORE making any transaction write.
    const [receiptSnap, userSnap, configSnap, productSnap, dailySnap] =
      await Promise.all([receiptRef, walletRef, configRef, productRef, dailyRef]
        .map(ref => tx.get(ref)));
    if (receiptSnap.exists) {
      const receipt = receiptSnap.data() || {};
      if (receipt.userId !== userId || receipt.platform !== platform ||
          receipt.catalogId !== catalogId) {
        throw Object.assign(new Error("Receipt was already applied elsewhere."),
          {status: 409});
      }
      // A signed refund may arrive before checkout.session.completed.
      // The tombstone prevents late callbacks from minting refunded coins.
      if (receipt.reversed === true) {
        return {alreadyCredited: true, coins: 0, reversed: true};
      }
      if (receipt.productId !== productId) {
        throw Object.assign(new Error("Receipt product mismatch."), {status: 409});
      }
      return {alreadyCredited: true, coins: Number(receipt.coins || 0)};
    }
    const policy = requireLiveEconomy(configSnap.data());
    requirePrivateWallet(userSnap);
    const product = productSnap.data() || {};
    const base = Number(product.coins);
    const priceCents = Math.round(Number(product.priceUsd) * 100);
    if (!productSnap.exists || product.active !== true ||
        !Number.isSafeInteger(base) || base <= 0 || base !== coins ||
        !Number.isSafeInteger(priceCents) || priceCents <= 0 ||
        (platform === "android" && product.androidProductId !== productId) ||
        (platform === "ios" && product.iosProductId !== productId) ||
        (platform === "web" && product.webPriceId !== productId)) {
      throw Object.assign(new Error("Purchase does not match the approved catalog."),
        {status: 409});
    }
    const limitCents = Math.round(
      Number(policy.purchaseDailyUsdLimit) * 100,
    );
    const spentCents = Number(dailySnap.data()?.purchaseCents || 0);
    if (!Number.isSafeInteger(limitCents) || limitCents <= 0 ||
        !Number.isSafeInteger(spentCents)) {
      throw Object.assign(new Error("Purchase daily limit is not configured."),
        {status: 503});
    }
    if (spentCents + priceCents > limitCents) {
      throw Object.assign(new Error("Daily purchase limit reached."), {status: 429});
    }
    if (userSnap.data()?.walletFrozen === true ||
        Number(userSnap.data()?.walletDebtCoins || 0) > 0) {
      throw Object.assign(new Error("Wallet requires payment review."), {status: 423});
    }
    const previousPurchases = Number(userSnap.data()?.purchasedCoins || 0);
    const firstRecharge = previousPurchases === 0 &&
      userSnap.data()?.firstRechargeUsed !== true;
    const reward = calculatePurchaseCredit({
      config: policy, baseCoins: base, platform, firstRecharge,
    });
    const balanceBefore = Number(userSnap.data()?.coins || 0);
    const balanceAfter = balanceBefore + reward.totalCoins;
    if (!Number.isSafeInteger(balanceBefore) ||
        !Number.isSafeInteger(balanceAfter)) {
      throw Object.assign(new Error("Coin ledger balance is invalid."), {status: 503});
    }
    tx.set(walletRef, {
      coins: balanceAfter,
      purchasedCoins: previousPurchases + reward.totalCoins,
      firstRechargeUsed: true,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    tx.set(dailyRef, {
      purchaseCents: spentCents + priceCents,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    tx.create(userRef.collection("wallet_transactions").doc(receiptKey), {
      type: "coin_purchase", amount: reward.totalCoins, currency: "coins",
      balanceBefore, balanceAfter, source: platform,
      catalogId, productId, receiptKey, baseCoins: base,
      bonusCoins: reward.bonusCoins, firstRecharge,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.create(db.collection("economy_audit").doc(receiptKey), {
      type: "coin_purchase", userId, platform, catalogId,
      productId, receiptKey, baseCoins: base,
      bonusCoins: reward.bonusCoins, creditedCoins: reward.totalCoins,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.create(receiptRef, {
      userId, platform, receiptId, productId, catalogId,
      baseCoins: base, bonusCoins: reward.bonusCoins,
      coins: reward.totalCoins, priceCents,
      purchasedAt: purchasedAt || null,
      creditedAt: FieldValue.serverTimestamp(),
      reversed: false,
    });
    return {alreadyCredited: false, coins: reward.totalCoins};
  });
}

app.get("/health", (_req, res) => {
  res.json({
    ok: true,
    service: "worldvoice-room-backend",
  });
});

app.post("/agora/token", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);
    const channelName = req.body?.channelName;
    const requestedRole =
      req.body?.role === "publisher" ? "publisher" : "subscriber";

    if (!validChannelName(channelName)) {
      return res.status(400).json({ error: "Invalid channelName." });
    }

    requireEnv(agoraAppId, "AGORA_APP_ID");
    requireEnv(agoraCertificate, "AGORA_APP_CERTIFICATE");

    const roomRef = db.collection("rooms").doc(channelName);
    const liveRef = db.collection("live_sessions").doc(channelName);
    const [roomSnap, liveSnap] = await Promise.all([
      roomRef.get(),
      liveRef.get(),
    ]);

    if (roomSnap.exists) {
      if (roomSnap.data()?.isOpen !== true) {
        return res.status(404).json({error: "Room is not open."});
      }
      const participantSnap =
        await roomRef.collection("participants").doc(user.uid).get();
      if (!participantSnap.exists) {
        return res.status(403).json({error: "User is not a room participant."});
      }
      const participant = participantSnap.data() || {};
      if (requestedRole === "publisher" && !isStageRole(participant.role)) {
        return res.status(403).json({
          error: "This participant is not allowed to publish room audio.",
        });
      }
    } else if (liveSnap.exists) {
      const live = liveSnap.data() || {};
      const heartbeatMs = live.hostHeartbeatAt?.toMillis?.() ?? 0;
      const fresh = live.isLive === true &&
        live.channelId === channelName &&
        heartbeatMs > Date.now() - 60000;
      if (!fresh) {
        return res.status(404).json({error: "Live session is not active."});
      }

      if (requestedRole === "publisher") {
        const isHost = live.hostId === user.uid;
        let approvedGuest = false;
        if (!isHost) {
          const requestSnap = await liveRef.collection("join_requests")
            .doc(user.uid).get();
          approvedGuest = requestSnap.data()?.status === "accepted";
        }
        if (!isHost && !approvedGuest) {
          return res.status(403).json({
            error: "This viewer is not approved to publish Live video.",
          });
        }
      } else if (live.hostId !== user.uid) {
        const viewerSnap = await liveRef.collection("viewers")
          .doc(user.uid).get();
        if (!viewerSnap.exists || viewerSnap.data()?.uid !== user.uid) {
          return res.status(403).json({
            error: "Join the Live before subscribing.",
          });
        }
      }
    } else {
      // A signed-in user may bootstrap a brand-new Live publisher channel.
      // It is not discoverable until the client creates live_sessions/{id}.
      if (!(requestedRole === "publisher" && channelName.startsWith("live_"))) {
        return res.status(404).json({error: "Room or Live session not found."});
      }
    }

    const uid = agoraUidForFirebaseUid(user.uid);
    const role =
      requestedRole === "publisher" ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

    const tokenSeconds = 60 * 60;
    const token = RtcTokenBuilder.buildTokenWithUid(
      agoraAppId,
      agoraCertificate,
      channelName,
      uid,
      role,
      tokenSeconds,
      tokenSeconds,
    );

    return res.json({
      token,
      uid,
      expiresIn: tokenSeconds,
    });
  } catch (error) {
    next(error);
  }
});

app.post("/ai/status", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);
    const context = req.body?.context === "live" ? "live" : "room";
    const roomId = String(req.body?.roomId || "").trim();

    if (!roomId) {
      return res.status(400).json({error: "roomId is required."});
    }

    const parentCollection = context === "live" ? "live_sessions" : "rooms";
    const parentRef = db.collection(parentCollection).doc(roomId);
    const parentSnap = await parentRef.get();
    if (!parentSnap.exists) {
      return res.status(404).json({error: "Room not found."});
    }

    let memberAllowed = false;
    if (context === "room") {
      memberAllowed = (
        await parentRef.collection("participants").doc(user.uid).get()
      ).exists;
    } else {
      const live = parentSnap.data() || {};
      memberAllowed = live.hostId === user.uid ||
        (await parentRef.collection("viewers").doc(user.uid).get()).exists;
    }
    if (!memberAllowed) {
      return res.status(403).json({error: "User is not in this room."});
    }

    requireEnv(openAiKey, "OPENAI_API_KEY");
    requireEnv(teacherModel, "OPENAI_TEACHER_MODEL");

    await openai.responses.create({
      model: teacherModel,
      store: false,
      max_output_tokens: 8,
      instructions: "Return exactly OK.",
      input: "OK",
    });

    return res.json({ok: true, available: true});
  } catch (error) {
    next(error);
  }
});

app.post(
  "/speech/transcribe",
  express.raw({type: ["audio/wav", "application/octet-stream"], limit: "768kb"}),
  async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);

      requireEnv(openAiKey, "OPENAI_API_KEY");
      requireEnv(transcribeModel, "OPENAI_TRANSCRIBE_MODEL");

      const context = req.query?.context === "live" ? "live" : "room";
      const roomId = String(req.query?.roomId || "").trim();
      if (!roomId) {
        return res.status(400).json({error: "roomId is required."});
      }

      const parentCollection = context === "live" ? "live_sessions" : "rooms";
      const roomRef = db.collection(parentCollection).doc(roomId);
      const roomSnap = await roomRef.get();

      if (!roomSnap.exists ||
          (context === "room" && roomSnap.data()?.isOpen !== true) ||
          (context === "live" && roomSnap.data()?.isLive !== true)) {
        return res.status(404).json({
          error: context === "live" ?
            "Live session is not active." : "Room is not open.",
        });
      }

      let memberAllowed = false;
      if (context === "room") {
        memberAllowed = (
          await roomRef.collection("participants").doc(user.uid).get()
        ).exists;
      } else {
        const live = roomSnap.data() || {};
        memberAllowed = live.hostId === user.uid ||
          (await roomRef.collection("viewers").doc(user.uid).get()).exists;
      }
      if (!memberAllowed) {
        return res.status(403).json({
          error: context === "live" ?
            "User is not in this Live." : "User is not in this room.",
        });
      }

      if (!Buffer.isBuffer(req.body) || req.body.length < 1024) {
        return res.json({ok: true, text: ""});
      }

      const file = await toFile(req.body, "worldvoice-speech.wav", {
        type: "audio/wav",
      });
      const transcription = await openai.audio.transcriptions.create({
        model: transcribeModel,
        file,
      });

      return res.json({
        ok: true,
        text: String(transcription.text || "").trim().slice(0, 400),
      });
    } catch (error) {
      next(error);
    }
  },
);

app.post("/teacher-ai", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);

    requireEnv(openAiKey, "OPENAI_API_KEY");
    requireEnv(teacherModel, "OPENAI_TEACHER_MODEL");

    const context = req.body?.context === "live" ? "live" : "room";
    const roomId = String(req.body?.roomId || "").trim();
    const captionId = String(req.body?.captionId || "").trim();

    if (!roomId || !captionId) {
      return res.status(400).json({error: "roomId and captionId are required."});
    }

    const parentCollection = context === "live" ? "live_sessions" : "rooms";
    const roomRef = db.collection(parentCollection).doc(roomId);
    const captionRef = roomRef.collection("captions").doc(captionId);
    const noteRef = roomRef.collection("teacher_ai_notes").doc(captionId);
    const roomSnap = await roomRef.get();

    if (!roomSnap.exists ||
        (context === "room" && roomSnap.data()?.isOpen !== true) ||
        (context === "live" && roomSnap.data()?.isLive !== true)) {
      return res.status(404).json({
        error: context === "live" ?
          "Live session is not active." : "Room is not open.",
      });
    }

    let memberAllowed = false;
    if (context === "room") {
      memberAllowed = (
        await roomRef.collection("participants").doc(user.uid).get()
      ).exists;
    } else {
      const live = roomSnap.data() || {};
      memberAllowed = live.hostId === user.uid ||
        (await roomRef.collection("viewers").doc(user.uid).get()).exists;
    }
    if (!memberAllowed) {
      return res.status(403).json({
        error: context === "live" ?
          "User is not in this Live." : "User is not in this room.",
      });
    }

    const existingNote = await noteRef.get();
    if (existingNote.exists) {
      return res.json({ok: true, cached: true});
    }

    const directText = String(req.body?.text || "").trim();
    let caption;
    if (directText) {
      const requestedUserId = String(req.body?.userId || user.uid);
      if (requestedUserId !== user.uid) {
        return res.status(403).json({error: "Caption owner mismatch."});
      }
      caption = {
        userId: user.uid,
        displayName: String(req.body?.displayName || "WorldVoice user"),
        text: directText.slice(0, 400),
        languageCode: String(req.body?.languageCode || "en").trim(),
      };
    } else {
      const captionSnap = await captionRef.get();
      if (!captionSnap.exists) {
        return res.status(404).json({error: "Caption not found."});
      }
      caption = captionSnap.data() || {};
      if (caption.userId !== user.uid) {
        return res.status(403).json({error: "Caption owner mismatch."});
      }
    }

    const text = String(caption.text || "").trim();
    const languageCode = String(caption.languageCode || "en").trim();
    const roomLanguageCode = String(
      req.body?.roomLanguageCode ||
      roomSnap.data()?.languageCode ||
      languageCode
    ).trim();

    if (!text) {
      return res.status(400).json({error: "Caption text is empty."});
    }

    const response = await openai.responses.create({
      model: teacherModel,
      store: false,
      instructions:
        "You are WorldVoice pronunciation and language coach. " +
        "Review the speaker transcript in the context of the room target language. " +
        "Never claim that you measured acoustic pronunciation because you received a transcript, not phoneme scores. " +
        "If the sentence is already natural, correction should be empty. " +
        "Otherwise provide one concise corrected sentence. " +
        "Give one short, practical pronunciation tip when useful, focusing on sounds, stress, or rhythm. " +
        "Return only valid JSON with exactly these keys: correction, pronunciationTip.",
      input:
        `Target room language: ${roomLanguageCode}\n` +
        `Speaker language hint: ${languageCode}\n` +
        `Transcript: ${text}`,
    });

    let result;
    try {
      result = JSON.parse(response.output_text || "{}");
    } catch {
      result = {};
    }

    const correction = typeof result.correction === "string" ?
      result.correction.trim().slice(0, 400) : "";
    const pronunciationTip = typeof result.pronunciationTip === "string" ?
      result.pronunciationTip.trim().slice(0, 240) : "";

    await noteRef.set({
      userId: user.uid,
      displayName: String(caption.displayName || "WorldVoice user"),
      captionId,
      originalText: text,
      correction,
      pronunciationTip,
      languageCode,
      model: teacherModel,
      createdAt: FieldValue.serverTimestamp(),
    });

    return res.json({
      ok: true,
      correction,
      pronunciationTip,
    });
  } catch (error) {
    next(error);
  }
});

app.post("/teacher-ai/ask", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);

    requireEnv(openAiKey, "OPENAI_API_KEY");
    requireEnv(teacherModel, "OPENAI_TEACHER_MODEL");

    const context = req.body?.context === "live" ? "live" : "room";
    const roomId = String(req.body?.roomId || "").trim();
    const prompt = String(req.body?.prompt || "").trim();
    const requestedRoomLanguage = String(
      req.body?.roomLanguageCode || "",
    ).trim();

    if (!roomId || !prompt) {
      return res.status(400).json({
        error: "roomId and prompt are required.",
      });
    }
    if (prompt.length > 1200) {
      return res.status(400).json({
        error: "Teacher AI questions are limited to 1200 characters.",
      });
    }

    const parentCollection = context === "live" ? "live_sessions" : "rooms";
    const roomRef = db.collection(parentCollection).doc(roomId);
    const roomSnap = await roomRef.get();

    if (!roomSnap.exists ||
        (context === "room" && roomSnap.data()?.isOpen !== true) ||
        (context === "live" && roomSnap.data()?.isLive !== true)) {
      return res.status(404).json({
        error: context === "live" ?
          "Live session is not active." : "Room is not open.",
      });
    }

    let memberAllowed = false;
    if (context === "room") {
      memberAllowed = (
        await roomRef.collection("participants").doc(user.uid).get()
      ).exists;
    } else {
      const live = roomSnap.data() || {};
      memberAllowed = live.hostId === user.uid ||
        (await roomRef.collection("viewers").doc(user.uid).get()).exists;
    }
    if (!memberAllowed) {
      return res.status(403).json({
        error: context === "live" ?
          "User is not in this Live." : "User is not in this room.",
      });
    }

    const roomLanguageCode =
      requestedRoomLanguage ||
      String(roomSnap.data()?.languageCode || "en").trim() ||
      "en";

    if (context === "room" && roomSnap.data()?.showTeacherAiSeat !== true) {
      return res.status(409).json({
        error: "Teacher AI seat is hidden in this room.",
      });
    }

    const conversationRef = roomRef
      .collection("_teacher_ai_conversations")
      .doc(user.uid);
    const conversationSnap = await conversationRef.get();
    const rawHistory = Array.isArray(conversationSnap.data()?.history) ?
      conversationSnap.data().history : [];
    const history = rawHistory
      .slice(-10)
      .filter(item => item && typeof item.text === "string" &&
        ["user", "assistant"].includes(item.role))
      .map(item => ({
        role: item.role,
        text: String(item.text).slice(0, 1200),
      }));

    const recentConversation = history.length === 0 ?
      "(No previous conversation in this room.)" :
      history.map(item =>
        `${item.role === "user" ? "Member" : "Teacher"}: ${item.text}`
      ).join("\n");

    const response = await openai.responses.create({
      model: teacherModel,
      store: false,
      instructions:
        "You are WorldVoice Teacher AI, a warm real-time language tutor and conversation partner inside a voice room. " +
        "Hold a natural conversation about whatever topic the member raises. " +
        "Understand the member even if they mix languages. " +
        "Answer primarily in the room target language so they can practice it. " +
        "If the member asks for a translation or explanation, you may briefly use their language when necessary. " +
        "Correct mistakes lightly and naturally only when useful; do not turn every reply into a grammar lesson. " +
        "Keep spoken replies concise, usually two to five sentences, and suitable for text-to-speech. " +
        "Ask a relevant follow-up question when that keeps the conversation moving. " +
        "Return only valid JSON with exactly one key: answer.",
      input:
        `Room target language: ${roomLanguageCode}\n` +
        `Recent conversation:\n${recentConversation}\n\n` +
        `Member says now: ${prompt}`,
    });

    let teacherResult;
    try {
      teacherResult = JSON.parse(response.output_text || "{}");
    } catch {
      teacherResult = {};
    }

    const answer = typeof teacherResult.answer === "string" ?
      teacherResult.answer.trim().slice(0, 2400) : "";
    if (!answer) {
      return res.status(502).json({error: "Teacher AI returned no answer."});
    }

    const nextHistory = [
      ...history,
      {role: "user", text: prompt.slice(0, 1200)},
      {role: "assistant", text: answer.slice(0, 2400)},
    ].slice(-12);
    await conversationRef.set({
      history: nextHistory,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    const voiceId = roomRef.collection("_voice_ids").doc().id;
    await roomRef.set({
      teacherAiVoice: {
        id: voiceId,
        userId: user.uid,
        answer,
        languageCode: roomLanguageCode,
        model: teacherModel,
        createdAt: FieldValue.serverTimestamp(),
      },
    }, {merge: true});

    return res.json({
      ok: true,
      answer,
      languageCode: roomLanguageCode,
    });
  } catch (error) {
    next(error);
  }
});

app.post("/translate", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);

    requireEnv(openAiKey, "OPENAI_API_KEY");
    requireEnv(teacherModel, "OPENAI_TEACHER_MODEL");

    const context = req.body?.context === "live" ? "live" : "room";
    const roomId = String(req.body?.roomId || "").trim();
    const text = String(req.body?.text || "").trim();
    const targetLanguageCode = String(
      req.body?.targetLanguageCode || "",
    ).trim().toLowerCase();

    if (!roomId || !text || !targetLanguageCode) {
      return res.status(400).json({
        error: "roomId, text and targetLanguageCode are required.",
      });
    }
    if (text.length > 500) {
      return res.status(400).json({
        error: "Room messages are limited to 500 characters.",
      });
    }
    if (!/^[a-z]{2,3}(?:-[a-z0-9]{2,8})?$/i.test(targetLanguageCode)) {
      return res.status(400).json({error: "Invalid target language."});
    }

    const parentCollection = context === "live" ? "live_sessions" : "rooms";
    const parentRef = db.collection(parentCollection).doc(roomId);
    const parentSnap = await parentRef.get();
    if (!parentSnap.exists ||
        (context === "room" && parentSnap.data()?.isOpen !== true) ||
        (context === "live" && parentSnap.data()?.isLive !== true)) {
      return res.status(404).json({
        error: context === "live" ? "Live session is not active." : "Room is not open.",
      });
    }

    let memberAllowed = false;
    if (context === "room") {
      memberAllowed = (await parentRef.collection("participants")
        .doc(user.uid).get()).exists;
    } else {
      const live = parentSnap.data() || {};
      memberAllowed = live.hostId === user.uid ||
        (await parentRef.collection("viewers").doc(user.uid).get()).exists;
    }
    if (!memberAllowed) {
      return res.status(403).json({
        error: context === "live" ? "User is not in this Live." : "User is not in this room.",
      });
    }

    const response = await openai.responses.create({
      model: teacherModel,
      store: false,
      instructions:
        "Translate the provided social chat message faithfully into the requested target language. " +
        "Automatically detect the source language. Preserve names, usernames, emojis, numbers and meaning. " +
        "Do not explain, annotate, censor, summarize, or answer the message. " +
        "If the text is already in the requested target language, return it unchanged. " +
        "Return only the translated message text.",
      input:
        `Target language code: ${targetLanguageCode}\n` +
        `Message: ${text}`,
    });

    const translation = String(response.output_text || "").trim().slice(0, 1200);
    if (!translation) {
      return res.status(502).json({error: "Translation returned no text."});
    }

    return res.json({
      ok: true,
      translation,
      targetLanguageCode,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * Uniform non-currency entitlement purchase/gift. VIP with coins is gifted
 * only; a user's own recurring VIP plan goes through verified store billing.
 */
app.post("/store/purchase", async (req, res, next) => {
  try {
    const sender = await authenticatedUser(req);
    const itemId = String(req.body?.itemId || "").trim();
    const requestedRecipient = String(req.body?.recipientId || "").trim();
    const recipientId = requestedRecipient || sender.uid;
    const gifting = recipientId !== sender.uid;
    const key = String(req.headers["idempotency-key"] || "").trim();
    if (!/^(background|frame|entrance|vip)__[A-Za-z0-9_-]{1,80}$/.test(itemId) ||
        !/^[A-Za-z0-9_-]{12,100}$/.test(key)) {
      return res.status(400).json({error: "Invalid item or idempotency key."});
    }
    const refKey = createHash("sha256")
      .update(`${sender.uid}:store:${key}`).digest("hex");
    const operationRef = db.collection("economy_store_operations").doc(refKey);
    const itemRef = db.collection("store_items").doc(itemId);
    const configRef = db.doc("economy_config/current");
    const payerRef = db.collection("users").doc(sender.uid);
    const payerWalletRef = privateWalletRef(payerRef);
    const recipientRef = db.collection("users").doc(recipientId);
    const recipientWalletRef = gifting ? privateWalletRef(recipientRef) : payerWalletRef;
    const inventoryRef = recipientRef.collection("inventory").doc(itemId);
    const friendRef = gifting ? payerRef.collection("following").doc(recipientId)
      : null;
    const day = new Date().toISOString().slice(0, 10);
    const dailyRef = payerRef.collection("economy_daily").doc(day);
    const outcome = await db.runTransaction(async tx => {
      const refs = [operationRef, itemRef, configRef, payerRef, payerWalletRef,
        inventoryRef, dailyRef, ...(gifting ? [recipientRef, recipientWalletRef, friendRef] : [])];
      const snaps = await Promise.all(refs.map(ref => tx.get(ref)));
      const [existing, itemSnap, configSnap, payerProfileSnap, payerSnap,
        ownedSnap, dailySnap] = snaps;
      if (existing.exists) {
        const old = existing.data() || {};
        if (old.senderId !== sender.uid || old.recipientId !== recipientId ||
            old.itemId !== itemId) {
          throw Object.assign(new Error("Idempotency key reused."), {status: 409});
        }
        return {...old.outcome, alreadyProcessed: true};
      }
      const policy = requireLiveEconomy(configSnap.data());
      requirePrivateWallet(payerSnap);
      if (gifting) requirePrivateWallet(snaps[8]);
      const item = itemSnap.data() || {};
      if (!itemSnap.exists || item.active !== true ||
          !["background", "frame", "entrance", "vip"].includes(item.type) ||
          !itemId.startsWith(item.type + "__")) {
        throw Object.assign(new Error("Store item unavailable."), {status: 404});
      }
      if (item.type === "vip" && !gifting) {
        throw Object.assign(new Error("Use verified store billing for personal VIP."),
          {status: 400});
      }
      const price = Number(item.priceCoins);
      const duration = item.durationDays == null
        ? null : Number(item.durationDays);
      if (!Number.isSafeInteger(price) || price <= 0 ||
          (duration != null && (!Number.isSafeInteger(duration) || duration <= 0)) ||
          (item.type === "vip" && duration == null)) {
        throw Object.assign(new Error("Store item price or duration is invalid."),
          {status: 503});
      }
      if (!payerProfileSnap.exists ||
          Number(payerSnap.data()?.giftLevel || 0) <
          Number(item.requiredGiftLevel || 0) ||
          (gifting && (!snaps[7].exists || !snaps[9].exists))) {
        throw Object.assign(new Error("User, gift level or friendship requirement failed."),
          {status: 403});
      }
      if (payerSnap.data()?.walletFrozen === true ||
          Number(payerSnap.data()?.walletDebtCoins || 0) > 0) {
        throw Object.assign(new Error("Wallet under payment review."), {status: 423});
      }
      const owner = gifting ? snaps[8].data() || {} : payerSnap.data() || {};
      const existingExpiry = item.type === "vip"
        ? owner.vipExpiresAt?.toMillis?.()
        : ownedSnap.data()?.expiresAt?.toMillis?.();
      if (ownedSnap.exists && item.type !== "vip" &&
          ownedSnap.data()?.expiresAt == null &&
          Number(ownedSnap.data()?.quantity || 0) > 0) {
        return {alreadyOwned: true, itemId, recipientId};
      }
      const now = Date.now();
      const expiresAt = duration == null ? null : Timestamp.fromMillis(
        Math.max(now, existingExpiry || now) + duration * 24 * 60 * 60 * 1000,
      );
      const before = Number(payerSnap.data()?.coins || 0);
      if (!Number.isSafeInteger(before) || before < price) {
        throw Object.assign(new Error("NOT_ENOUGH_COINS"), {status: 409});
      }
      const dailyGift = Number(dailySnap.data()?.giftCoins || 0);
      if (gifting && (!Number.isSafeInteger(policy.giftingDailyCoinLimit) ||
          policy.giftingDailyCoinLimit <= 0 ||
          !Number.isSafeInteger(dailyGift) ||
          dailyGift + price > policy.giftingDailyCoinLimit)) {
        throw Object.assign(new Error("Gifting daily limit exceeded."), {status: 429});
      }
      tx.update(payerWalletRef, {
        coins: before - price,
        updatedAt: FieldValue.serverTimestamp(),
      });
      if (gifting) {
        tx.set(dailyRef, {
          giftCoins: dailyGift + price,
          updatedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
      }
      tx.set(inventoryRef, {
        itemId, type: item.type, source: gifting ? "gift" : "purchase",
        giftedBy: gifting ? sender.uid : null,
        quantity: 1, freeGiftBalance: 0,
        name: String(item.name || itemId),
        ...(item.type === "background" ? {
          themeId: String(item.themeId || item.legacyId || itemId),
          backgroundUrl: item.previewUrl || null,
        } : {}),
        expiresAt,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      if (item.type === "vip") {
        tx.update(recipientWalletRef, {vipExpiresAt: expiresAt});
      }
      if (item.type === "background") {
        // Temporary mirrored legacy read model; remove after all clients
        // consume users/{uid}/inventory and background migration is complete.
        tx.set(recipientRef.collection("room_backgrounds")
          .doc(String(item.themeId || item.legacyId || itemId)), {
          itemId, themeId: String(item.themeId || item.legacyId || itemId),
          backgroundUrl: item.previewUrl || null,
          name: String(item.name || "WorldVoice Background"),
          expiresAt, source: gifting ? "gift" : "purchase",
          purchasedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
      }
      tx.create(payerRef.collection("wallet_transactions").doc(refKey), {
        type: gifting ? "item_gift" : "item_purchase",
        amount: -price, currency: "coins",
        balanceBefore: before, balanceAfter: before - price,
        source: "store_items", itemId, recipientId,
        operationId: refKey,
        createdAt: FieldValue.serverTimestamp(),
      });
      const response = {
        itemId, recipientId, balanceAfter: before - price,
        expiresAt: expiresAt ? expiresAt.toDate().toISOString() : null,
      };
      tx.create(operationRef, {
        senderId: sender.uid, recipientId, itemId,
        outcome: response, createdAt: FieldValue.serverTimestamp(),
      });
      tx.create(db.collection("economy_audit").doc(refKey), {
        type: gifting ? "item_gift" : "item_purchase",
        senderId: sender.uid, recipientId, itemId,
        paidCoins: price, createdAt: FieldValue.serverTimestamp(),
      });
      return {...response, alreadyProcessed: false};
    });
    res.json({ok: true, ...outcome});
  } catch (error) {
    next(error);
  }
});

app.post("/store/claim-reward", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);
    const itemId = String(req.body?.itemId || "").trim();
    const rewardId = String(req.body?.rewardId || "").trim();

    if (!itemId || !rewardId) {
      return res.status(400).json({
        error: "itemId and rewardId are required.",
      });
    }

    const userRef = db.collection("users").doc(user.uid);
    const itemRef = db.collection("room_shop_items").doc(itemId);
    const rewardRef = userRef.collection("room_rewards").doc(rewardId);

    const result = await db.runTransaction(async (tx) => {
      const [itemSnap, rewardSnap] = await Promise.all([
        tx.get(itemRef),
        tx.get(rewardRef),
      ]);

      if (!itemSnap.exists) {
        const error = new Error("Store item not found.");
        error.status = 404;
        throw error;
      }

      if (!rewardSnap.exists) {
        const error = new Error("Background reward not found.");
        error.status = 404;
        throw error;
      }

      const item = itemSnap.data() || {};
      const reward = rewardSnap.data() || {};

      if (item.active !== true || item.type !== "background") {
        const error = new Error("This background is not available.");
        error.status = 409;
        throw error;
      }

      if (reward.type !== "background_month" || reward.claimedAt != null) {
        const error = new Error("This reward is not available.");
        error.status = 409;
        throw error;
      }

      const rewardExpiry = reward.expiresAt?.toDate?.() || null;
      if (rewardExpiry && rewardExpiry.getTime() <= Date.now()) {
        const error = new Error("This background reward has expired.");
        error.status = 409;
        throw error;
      }

      const themeId = String(item.themeId || itemId).trim();
      const name = String(item.name || "WorldVoice Background").trim();
      if (!themeId) {
        const error = new Error("Store item configuration is invalid.");
        error.status = 500;
        throw error;
      }

      const entitlementRef = userRef
        .collection("room_backgrounds")
        .doc(themeId);
      const oneMonthFromNow = Date.now() + 30 * 24 * 60 * 60 * 1000;
      const finalExpiryMillis = rewardExpiry
        ? Math.min(rewardExpiry.getTime(), oneMonthFromNow)
        : oneMonthFromNow;
      const expiresAt = Timestamp.fromMillis(finalExpiryMillis);

      tx.set(
        entitlementRef,
        {
          itemId,
          themeId,
          name,
          backgroundUrl: String(item.previewUrl || "").trim(),
          source: "room_level_reward",
          sourceRewardId: rewardId,
          purchasedAt: FieldValue.serverTimestamp(),
          expiresAt,
        },
        { merge: true },
      );

      tx.set(
        rewardRef,
        {
          claimedAt: FieldValue.serverTimestamp(),
          claimedItemId: itemId,
          claimedThemeId: themeId,
        },
        { merge: true },
      );

      return { themeId, expiresAt: expiresAt.toMillis() };
    });

    return res.json({ ok: true, ...result });
  } catch (error) {
    next(error);
  }
});


/**
 * Unified gift contract for room/live/chat.
 * Live authorization is based on an active server-timestamped Live session,
 * atomic viewer membership, and host-approved active camera guests.
 * Idempotency-Key is mandatory; clients reuse it for a checkout retry.
 */

/**
 * WEB ONLY; intended for the WorldVoice website, NOT a mobile alternative
 * billing button. Storefront eligibility checks belong in app release logic.
 * Stripe's server-side price ID is taken from approved coin_products only.
 */
app.post("/web/checkout", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);
    if (!stripe) {
      return res.status(503).json({error: "Web checkout is not configured."});
    }
    const successUrl = String(process.env.WEB_CHECKOUT_SUCCESS_URL || "").trim();
    const cancelUrl = String(process.env.WEB_CHECKOUT_CANCEL_URL || "").trim();
    if (!successUrl.startsWith("https://") ||
        !cancelUrl.startsWith("https://")) {
      return res.status(503).json({error: "Web checkout redirect URLs are missing."});
    }
    const catalogId = String(req.body?.catalogId || "").trim();
    if (!/^[A-Za-z0-9_-]{1,80}$/.test(catalogId)) {
      return res.status(400).json({error: "Invalid product ID."});
    }
    requireLiveEconomy((await db.doc("economy_config/current").get()).data());
    const snap = await db.collection("coin_products").doc(catalogId).get();
    const product = snap.data() || {};
    const expectedCents = Math.round(Number(product.priceUsd) * 100);
    if (!snap.exists || product.active !== true ||
        typeof product.webPriceId !== "string" || !product.webPriceId ||
        !Number.isSafeInteger(expectedCents) || expectedCents <= 0) {
      return res.status(404).json({error: "Web product is not active."});
    }
    // Verify that the actual Stripe price matches Firestore; the client never
    // supplies quantity, USD amount, discount, price ID or credited coins.
    const price = await stripe.prices.retrieve(product.webPriceId);
    if (!price.active || price.type !== "one_time" ||
        price.currency !== "usd" || price.unit_amount !== expectedCents) {
      return res.status(503).json({error: "Stripe catalog mismatch."});
    }
    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      client_reference_id: user.uid,
      metadata: {catalogId},
      line_items: [{price: product.webPriceId, quantity: 1}],
      success_url: successUrl,
      cancel_url: cancelUrl,
    });
    res.json({ok: true, checkoutUrl: session.url});
  } catch (error) {
    next(error);
  }
});

app.post("/gift/send", async (req, res, next) => {
  try {
    const sender = await authenticatedUser(req);
    const {context, contextId, recipientId, giftId} = req.body || {};
    const quantity = Number(req.body?.quantity);
    const requestKey = String(req.headers["idempotency-key"] || "").trim();
    if (!["room", "live", "chat"].includes(context) ||
        !(context === "chat" ? /^[a-f0-9]{64}$/.test(contextId) :
          validChannelName(contextId)) ||
        typeof recipientId !== "string" || !recipientId.trim() ||
        recipientId === sender.uid ||
        typeof giftId !== "string" ||
        !/^[A-Za-z0-9_-]{1,80}$/.test(giftId) ||
        !Number.isSafeInteger(quantity) || quantity <= 0 ||
        !/^[A-Za-z0-9_-]{12,100}$/.test(requestKey)) {
      return res.status(400).json({error: "Invalid gift request or idempotency key."});
    }
    if (context !== "room" && recipientId === "teacher_ai") {
      return res.status(400).json({error: "AI gift XP is room-only."});
    }
    const requestHash = createHash("sha256")
      .update(`${sender.uid}:${requestKey}`).digest("hex");
    const eventRef = db.collection("economy_gift_operations").doc(requestHash);
    const senderRef = db.collection("users").doc(sender.uid);
    const senderWalletRef = privateWalletRef(senderRef);
    const recipientRef = recipientId === "teacher_ai" ? null
      : db.collection("users").doc(recipientId);
    const recipientWalletRef = recipientRef ? privateWalletRef(recipientRef) : null;
    const inventoryRef = senderRef.collection("inventory")
      .doc(`gift__${giftId}`);
    const itemRef = db.collection("store_items").doc(`gift__${giftId}`);
    const roomRef = context === "chat"
      ? db.collection("chats").doc(contextId)
      : context === "live"
        ? db.collection("live_sessions").doc(contextId)
        : db.collection("rooms").doc(contextId);
    const senderMemberRef = context === "room"
      ? roomRef.collection("participants").doc(sender.uid)
      : context === "live"
        ? roomRef.collection("viewers").doc(sender.uid)
        : roomRef;
    const recipientMemberRef = recipientRef
      ? context === "room"
        ? roomRef.collection("participants").doc(recipientId)
        : context === "live"
          ? roomRef.collection("join_requests").doc(recipientId)
          : roomRef
      : null;
    const senderFollow = context === "chat"
      ? senderRef.collection("following").doc(recipientId) : null;
    const recipientFollow = context === "chat"
      ? recipientRef.collection("following").doc(sender.uid) : null;
    const configRef = db.collection("economy_config").doc("current");
    const giftEventRef = context === "chat"
      ? roomRef.collection("messages").doc(requestHash)
      : roomRef.collection("gifts").doc(requestHash);

    const outcome = await db.runTransaction(async (tx) => {
      // All reads before writes (Firestore transaction requirement).
      const refs = [eventRef, configRef, itemRef, roomRef, senderMemberRef,
        senderRef, senderWalletRef, inventoryRef, ...(recipientRef
          ? [recipientMemberRef, recipientRef, recipientWalletRef] : []),
        ...(senderFollow ? [senderFollow, recipientFollow] : [])];
      const snapshots = await Promise.all(refs.map(ref => tx.get(ref)));
      const [existing, configSnap, itemSnap, roomSnap, senderMember,
        senderProfileSnap, senderSnap, freeGiftSnap] = snapshots;
      if (existing.exists) {
        const data = existing.data();
        if (data.userId !== sender.uid || data.context !== context ||
            data.contextId !== contextId || data.recipientId !== recipientId ||
            data.giftId !== giftId || data.quantity !== quantity) {
          throw Object.assign(new Error("Idempotency key reused for another request."),
            {status: 409});
        }
        return {...data.outcome, alreadyProcessed: true};
      }
      if (context === "room") {
        if (roomSnap.data()?.isOpen !== true ||
            !senderMember.exists ||
            (recipientMemberRef && !snapshots[8].exists)) {
          throw Object.assign(new Error("Room membership is required."),
            {status: 403});
        }
      } else if (context === "live") {
        const live = roomSnap.data() || {};
        const heartbeatMs = live.hostHeartbeatAt?.toMillis?.() ?? 0;
        const liveFresh = roomSnap.exists &&
          live.isLive === true &&
          live.channelId === contextId &&
          heartbeatMs > Date.now() - 60000;
        const senderIsHost = live.hostId === sender.uid;
        const senderIsViewer = senderMember.exists &&
          senderMember.data()?.uid === sender.uid;
        const recipientIsHost = live.hostId === recipientId;
        const recipientRequest = snapshots[8]?.data() || {};
        const recipientIsGuest = snapshots[8]?.exists &&
          recipientRequest.uid === recipientId &&
          recipientRequest.status === "accepted";
        if (!liveFresh || (!senderIsHost && !senderIsViewer) ||
            (!recipientIsHost && !recipientIsGuest)) {
          throw Object.assign(new Error("Active Live membership is required."),
            {status: 403});
        }
      } else {
        if (!roomSnap.exists ||
            chatIdFor(sender.uid, recipientId) !== contextId ||
            !snapshots[11]?.exists || !snapshots[12]?.exists) {
          throw Object.assign(new Error("Mutual following required for chat gifts."),
            {status: 403});
        }
        assertChatMembership(roomSnap.data(), sender.uid, recipientId);
      }
      const config = requireLiveEconomy(configSnap.data());
      requirePrivateWallet(senderSnap);
      if (recipientRef) requirePrivateWallet(snapshots[10]);
      const item = itemSnap.data();
      const price = Number(item?.priceCoins);
      if (!itemSnap.exists || item.type !== "gift" || item.active !== true ||
          !Number.isSafeInteger(price) || price <= 0) {
        throw Object.assign(new Error("This gift is unavailable."), {status: 404});
      }
      if (!senderProfileSnap.exists ||
          (recipientRef && !snapshots[9].exists)) {
        throw Object.assign(new Error("Gift wallet profiles are unavailable."),
          {status: 409});
      }
      const senderData = senderSnap.data() || {};
      if (Number(senderData.giftLevel || 0) <
          Number(item.requiredGiftLevel || 0)) {
        throw Object.assign(new Error("Gift level requirement not met."),
          {status: 403});
      }
      const now = Date.now();
      const freeData = freeGiftSnap.data() || {};
      const freeExpiry = freeData.expiresAt?.toMillis?.() ?? null;
      const freeBalance = freeExpiry !== null && freeExpiry <= now ? 0
        : Number(freeData.freeGiftBalance || 0);
      const amounts = calculateGiftSettlement({
        config, priceCoins: price, quantity, freeGiftBalance: freeBalance,
      });
      if (senderData.walletFrozen === true ||
          Number(senderData.walletDebtCoins || 0) > 0) {
        throw Object.assign(new Error("Wallet under payment review."), {status: 423});
      }
      const balance = Number(senderData.coins || 0);
      if (!Number.isSafeInteger(balance) || balance < amounts.chargedCoins) {
        throw Object.assign(new Error("NOT_ENOUGH_COINS"), {status: 409});
      }
      const after = balance - amounts.chargedCoins;
      const roomXp = Number(roomSnap.data()?.roomXp || 0);
      if (recipientId === "teacher_ai" && !Number.isSafeInteger(roomXp +
          amounts.giftLevelPoints)) {
        throw Object.assign(new Error("Room XP exceeds safe limits."), {status: 400});
      }
      // Server-enforced sender daily spend limit. Not configured => stop.
      if (!Number.isSafeInteger(config.giftingDailyCoinLimit) ||
          config.giftingDailyCoinLimit <= 0) {
        throw Object.assign(new Error("Gifting daily limit not configured."),
          {status: 503});
      }
      const day = new Date(now).toISOString().slice(0, 10);
      const dailyRef = senderRef.collection("economy_daily").doc(day);
      const dailySnap = await tx.get(dailyRef);
      const spent = Number(dailySnap.data()?.giftCoins || 0);
      if (!Number.isSafeInteger(spent) ||
          spent + amounts.chargedCoins > config.giftingDailyCoinLimit) {
        throw Object.assign(new Error("Daily gift limit reached."), {status: 429});
      }
      const recipientData = recipientRef ? snapshots[10].data() || {} : null;
      const recipientProfile = recipientRef ? snapshots[9].data() || {} : null;
      const recipientBefore = recipientData
        ? Number(recipientData.diamondsPending || 0) : 0;
      const receiverAfter = recipientBefore + amounts.pendingDiamonds;
      if (!Number.isSafeInteger(receiverAfter)) {
        throw Object.assign(new Error("Recipient settlement exceeds limits."),
          {status: 400});
      }
      const holdUntil = Timestamp.fromMillis(
        now + config.holdDays * 24 * 60 * 60 * 1000,
      );
      const outcome = {
        giftId, quantity, freeUnits: amounts.freeUnits,
        chargedCoins: amounts.chargedCoins, balanceAfter: after,
        pendingDiamonds: recipientRef ? amounts.pendingDiamonds : 0,
        holdUntil: recipientRef ? holdUntil.toDate().toISOString() : null,
      };
      tx.set(senderWalletRef, {
        coins: after,
        giftSentPoints: FieldValue.increment(amounts.chargedCoins),
        giftLevelPoints: FieldValue.increment(amounts.giftLevelPoints),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      if (freeGiftSnap.exists && amounts.freeUnits > 0) {
        tx.update(inventoryRef, {
          freeGiftBalance: freeBalance - amounts.freeUnits,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
      tx.set(dailyRef, {
        giftCoins: spent + amounts.chargedCoins,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      tx.create(senderRef.collection("wallet_transactions").doc(requestHash), {
        type: "gift_send", amount: -amounts.chargedCoins, currency: "coins",
        balanceBefore: balance, balanceAfter: after, source: context,
        sourceId: contextId, itemId: giftId, quantity,
        freeUnits: amounts.freeUnits, operationId: requestHash,
        createdAt: FieldValue.serverTimestamp(),
      });
      if (recipientRef) {
        tx.set(recipientWalletRef, {
          diamondsPending: receiverAfter,
          giftReceivedPoints: FieldValue.increment(amounts.chargedCoins),
          updatedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
        if (amounts.pendingDiamonds > 0) {
          tx.create(recipientRef.collection("diamond_lots").doc(requestHash), {
            status: "pending", diamonds: amounts.pendingDiamonds,
            senderId: sender.uid, source: context,
            sourceId: contextId, giftId, operationId: requestHash,
            holdUntil, createdAt: FieldValue.serverTimestamp(),
          });
        }
        tx.create(recipientRef.collection("wallet_transactions")
          .doc(requestHash), {
          type: "gift_received_pending", amount: amounts.pendingDiamonds,
          currency: "diamonds_pending", balanceBefore: recipientBefore,
          balanceAfter: receiverAfter, holdUntil, source: context,
          sourceId: contextId, senderId: sender.uid, itemId: giftId,
          operationId: requestHash, createdAt: FieldValue.serverTimestamp(),
        });
      } else {
        tx.update(roomRef, {
          roomXp: roomXp + amounts.giftLevelPoints,
        });
      }
      tx.create(giftEventRef, {
        ...(context === "chat" ? {type: "gift"} : {}),
        senderId: sender.uid,
        senderName: String(senderProfileSnap.data()?.displayName || "WorldVoice user"),
        recipientId, recipientName: recipientRef
          ? String(recipientProfile.displayName || "WorldVoice member")
          : "Teacher AI",
        giftId, points: amounts.chargedCoins, quantity,
        animationUrl: item.animationUrl || null,
        createdAt: FieldValue.serverTimestamp(),
      });
      if (context === "chat") {
        tx.update(roomRef, {
          latestText: "🎁 Gift",
          lastMessageAt: FieldValue.serverTimestamp(),
        });
      }
      tx.create(eventRef, {
        userId: sender.uid, context, contextId, recipientId,
        giftId, quantity, outcome,
        createdAt: FieldValue.serverTimestamp(),
      });
      tx.create(db.collection("economy_audit").doc(requestHash), {
        type: "gift_send", senderId: sender.uid, recipientId, context,
        contextId, giftId, quantity, chargedCoins: amounts.chargedCoins,
        freeUnits: amounts.freeUnits, createdAt: FieldValue.serverTimestamp(),
      });
      return {...outcome, alreadyProcessed: false};
    });
    res.json({ok: true, ...outcome});
  } catch (error) {
    next(error);
  }
});

app.post("/iap/verify", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);
    const platform = String(req.body?.platform || "").trim().toLowerCase();
    const productId = String(req.body?.productId || "").trim();
    const purchaseId = String(req.body?.purchaseId || "").trim();
    const verificationData = String(req.body?.verificationData || "").trim();

    if (!["android", "ios"].includes(platform)) {
      return res.status(400).json({ error: "Unsupported purchase platform." });
    }

    if (!productId || !verificationData) {
      return res.status(400).json({
        error: "productId and verificationData are required.",
      });
    }

    const catalog = await coinProductFor(platform, productId);
    let verified;

    if (platform === "android") {
      verified = await verifyGooglePlayPurchase(
        productId,
        verificationData,
      );
    } else {
      const clientPayload = decodeJwsPayload(verificationData);
      const transactionId =
        purchaseId || String(clientPayload?.transactionId || "").trim();

      if (!transactionId) {
        return res.status(400).json({
          error: "Apple transaction ID is missing.",
        });
      }

      const transaction = await fetchAppleTransaction(
        transactionId,
        clientPayload?.environment,
      );

      if (
        String(transaction.productId || "") !== productId ||
        String(transaction.bundleId || "") !== iosBundleId ||
        transaction.revocationDate != null
      ) {
        return res.status(409).json({
          error: "Apple transaction does not match this coin product.",
        });
      }

      verified = {
        receiptId: String(transaction.transactionId || transactionId),
        purchasedAt: Number(transaction.purchaseDate || 0),
      };
    }

    const credit = await creditVerifiedCoins({
      userId: user.uid,
      platform,
      receiptId: verified.receiptId,
      productId,
      catalogId: catalog.catalogId,
      coins: catalog.coins,
      purchasedAt: verified.purchasedAt,
    });

    return res.json({
      ok: true,
      coinsAdded: credit.coins,
      alreadyCredited: credit.alreadyCredited,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * Host-only quiz creation. The correct answer never leaves the trusted
 * backend and may never be read by another authenticated client.
 */
app.post("/quiz/start", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);
    const roomId = String(req.body?.roomId || "").trim();
    if (!roomId || roomId.length > 160) {
      return res.status(400).json({error: "Invalid room ID."});
    }
    const draft = validateQuizDraft(req.body || {});
    const roomRef = db.collection("rooms").doc(roomId);
    const roomSnap = await roomRef.get();
    if (!roomSnap.exists || roomSnap.data()?.isOpen !== true) {
      return res.status(404).json({error: "Room is not open."});
    }
    if (roomSnap.data()?.hostId !== user.uid) {
      return res.status(403).json({error: "Only the host may start a quiz."});
    }
    const previous = await roomRef.collection("quiz_answers").get();
    if (previous.size > 400) {
      return res.status(409).json({
        error: "Too many previous quiz answers; finish cleanup first.",
      });
    }
    const roundId = randomUUID();
    const batch = db.batch();
    for (const answer of previous.docs) batch.delete(answer.ref);
    batch.set(roomRef.collection("quiz_private").doc("current"), {
      correctIndex: draft.correctIndex,
      startedAt: FieldValue.serverTimestamp(),
      roundId,
      status: "open",
      hostId: user.uid,
    });
    batch.update(roomRef, {
      quiz: {
        question: draft.question,
        options: draft.options,
        roundId,
        revealed: false,
        // No client-visible correctIndex. Until a server-side reward ledger
        // uses owner-only wallets, every result is non-monetary practice.
        practiceOnly: true,
        startedAt: FieldValue.serverTimestamp(),
      },
      updatedAt: FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return res.json({ok: true, roundId});
  } catch (error) {
    next(error);
  }
});

/**
 * Legacy client-created quizzes still function as FREE practice using the
 * on-device fallback. This endpoint refuses to credit a public correctIndex.
 * Trusted server-created rounds are scored only using quiz_private/current.
 */
app.post("/quiz/finish", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);
    const roomId = String(req.body?.roomId || "").trim();
    if (!roomId || roomId.length > 160) {
      return res.status(400).json({error: "Invalid room ID."});
    }
    const roomRef = db.collection("rooms").doc(roomId);
    const privateRef = roomRef.collection("quiz_private").doc("current");
    const [roomSnap, privateSnap] = await Promise.all([
      roomRef.get(), privateRef.get(),
    ]);
    if (!roomSnap.exists || roomSnap.data()?.isOpen !== true) {
      return res.status(404).json({error: "Room is not open."});
    }
    if (roomSnap.data()?.hostId !== user.uid) {
      return res.status(403).json({error: "Only the host can finish the quiz."});
    }
    const quiz = roomSnap.data()?.quiz || {};
    const secret = privateSnap.data() || {};
    if (!privateSnap.exists || !secret.roundId ||
        quiz.roundId !== secret.roundId ||
        !Number.isInteger(secret.correctIndex)) {
      return res.status(409).json({
        error: "This quiz has no verified private answer; use free practice mode.",
      });
    }
    if (quiz.revealed === true || secret.status === "closed") {
      return res.json({ok: true, alreadyFinished: true, winners: quiz.winners || []});
    }
    const answersSnap = await roomRef.collection("quiz_answers").get();
    const winners = quizWinners({
      answers: answersSnap.docs.map(doc => ({id: doc.id, ...doc.data()})),
      correctIndex: secret.correctIndex,
      startedAt: secret.startedAt,
      roundId: secret.roundId,
    });
    const result = await db.runTransaction(async tx => {
      const [currentRoom, currentSecret] = await Promise.all([
        tx.get(roomRef), tx.get(privateRef),
      ]);
      const publicQuiz = currentRoom.data()?.quiz || {};
      const privateQuiz = currentSecret.data() || {};
      if (currentRoom.data()?.hostId !== user.uid ||
          publicQuiz.roundId !== secret.roundId ||
          privateQuiz.roundId !== secret.roundId) {
        const conflict = new Error("Quiz round changed; retry.");
        conflict.status = 409;
        throw conflict;
      }
      if (publicQuiz.revealed === true || privateQuiz.status !== "open") {
        return {alreadyFinished: true, winners: publicQuiz.winners || []};
      }
      tx.update(privateRef, {
        status: "closed",
        closedAt: FieldValue.serverTimestamp(),
      });
      tx.update(roomRef, {
        "quiz.correctIndex": privateQuiz.correctIndex,
        "quiz.revealed": true,
        "quiz.practiceOnly": true,
        "quiz.winners": winners,
        "quiz.firstPrizeCoins": 0,
        "quiz.rewardedAt": FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return {alreadyFinished: false, winners};
    });
    return res.json({ok: true, practiceOnly: true, ...result});
  } catch (error) {
    next(error);
  }
});


/**
 * Non-monetary, server-verified room missions. Device buttons cannot grant
 * XP or level rewards. Config-required missions stay disabled without owner
 * approved values; no task mints coins, diamonds or cashout inventory.
 */
const ROOM_TASK_KEYS = ["ten_minutes", "host_five", "three_gifts", "stay_hours"];
const roomTaskDay = () => new Date().toISOString().slice(0, 10);

function roomTaskId(key, uid, day) {
  const period = (key === "ten_minutes" || key === "stay_hours") ? day : "once";
  return `${key}_${uid}_${period}`;
}
function joinedMinutes(participant, nowMs) {
  const joined = participant?.joinedAt?.toMillis?.();
  if (!Number.isSafeInteger(joined) || joined > nowMs) return 0;
  return Math.max(0, Math.floor((nowMs - joined) / 60000));
}

app.get("/room/tasks/status", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);
    const roomId = String(req.query.roomId || "").trim();
    if (!roomId || roomId.length > 160) {
      return res.status(400).json({error: "Invalid room ID."});
    }
    const roomRef = db.collection("rooms").doc(roomId);
    const participantRef = roomRef.collection("participants").doc(user.uid);
    const now = Date.now();
    const day = roomTaskDay();
    const [room, participant, members, gifts, config, ...completions] =
      await Promise.all([
        roomRef.get(),
        participantRef.get(),
        roomRef.collection("participants").get(),
        roomRef.collection("gifts").where("senderId", "==", user.uid)
          .limit(3).get(),
        db.doc("room_task_config/current").get(),
        ...ROOM_TASK_KEYS.map(key =>
          roomRef.collection("task_completions")
            .doc(roomTaskId(key, user.uid, day)).get()),
      ]);
    if (!room.exists || room.data()?.isOpen !== true || !participant.exists) {
      return res.status(403).json({error: "Join an open room to view its tasks."});
    }
    const isHost = room.data()?.hostId === user.uid;
    const guestCount = isHost ?
      members.docs.filter(doc => doc.id !== user.uid).length : 0;
    const minutes = joinedMinutes(participant.data(), now);
    const progress = {minutes, guestCount, giftsSent: gifts.size};
    const configData = config.data() || {};
    const missions = ROOM_TASK_KEYS.map((key, index) => {
      let spec;
      try {
        spec = roomTaskSpec(key, configData);
      } catch (error) {
        if (error.status !== 503) throw error;
        return {key, configured: false, claimed: completions[index].exists,
          requiredMinutes: key === "stay_hours" ? null : undefined,
          xp: null};
      }
      const current = key === "ten_minutes" || key === "stay_hours"
        ? minutes : key === "host_five" ? guestCount : gifts.size;
      const required = spec.requiredMinutes ?? spec.requiredCount;
      return {key, configured: true, claimed: completions[index].exists,
        eligible: current >= required, current, required, xp: spec.xp};
    });
    const xp = Number(room.data()?.roomXp || 0);
    return res.json({ok: true, roomId, xp, level: roomLevelFromXp(xp),
      maxLevel: 60, progress, missions});
  } catch (error) {
    next(error);
  }
});

app.post("/room/tasks/claim", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);
    const roomId = String(req.body?.roomId || "").trim();
    const taskKey = String(req.body?.taskKey || "").trim();
    if (!roomId || roomId.length > 160 || !ROOM_TASK_KEYS.includes(taskKey)) {
      return res.status(400).json({error: "Invalid room mission."});
    }
    const roomRef = db.collection("rooms").doc(roomId);
    const memberRef = roomRef.collection("participants").doc(user.uid);
    const configRef = db.doc("room_task_config/current");
    const day = roomTaskDay();
    const completionRef = roomRef.collection("task_completions")
      .doc(roomTaskId(taskKey, user.uid, day));
    const now = Date.now();

    const outcome = await db.runTransaction(async tx => {
      // Read all snapshots and evidence BEFORE the first transaction write.
      const [room, member, config, prior, members, gifts] = await Promise.all([
        tx.get(roomRef), tx.get(memberRef), tx.get(configRef),
        tx.get(completionRef),
        taskKey === "host_five"
          ? tx.get(roomRef.collection("participants")) : Promise.resolve(null),
        taskKey === "three_gifts"
          ? tx.get(roomRef.collection("gifts").where(
              "senderId", "==", user.uid).limit(3))
          : Promise.resolve(null),
      ]);
      if (!room.exists || room.data()?.isOpen !== true || !member.exists) {
        throw Object.assign(new Error("Join an open room first."), {status: 403});
      }
      if (prior.exists) return {...prior.data().outcome, alreadyProcessed: true};
      const spec = roomTaskSpec(taskKey, config.data());
      let count = 0;
      switch (taskKey) {
        case "ten_minutes":
        case "stay_hours":
          count = joinedMinutes(member.data(), now);
          break;
        case "host_five":
          if (room.data()?.hostId !== user.uid) {
            throw Object.assign(new Error("Only the host may claim this mission."),
              {status: 403});
          }
          count = members.docs.filter(doc => doc.id !== user.uid).length;
          break;
        case "three_gifts":
          count = gifts.size;
          break;
      }
      const required = spec.requiredMinutes ?? spec.requiredCount;
      if (count < required) {
        throw Object.assign(new Error("Mission conditions are not verified yet."),
          {status: 409});
      }
      const previousXp = Number(room.data()?.roomXp || 0);
      const advancement = advanceRoomLevel(previousXp, spec.xp);
      const result = {taskKey, awardedXp: advancement.awardedXp,
        roomXp: advancement.nextXp, roomLevel: advancement.newLevel,
        unlockedLevels: advancement.unlockedLevels, completedAtMillis: now};
      tx.create(completionRef, {
        taskKey, userId: user.uid, points: advancement.awardedXp,
        periodKey: day, evidence: {observed: count, required},
        outcome: result, completedAt: FieldValue.serverTimestamp(),
      });
      tx.update(roomRef, {
        roomXp: advancement.nextXp,
        roomLevel: advancement.newLevel,
        lastTaskCompletionId: completionRef.id,
        updatedAt: FieldValue.serverTimestamp(),
      });
      for (const level of advancement.unlockedLevels) {
        tx.set(roomRef.collection("rewards").doc(`level_${level}`), {
          level, type: level === 5 ? "background_month" : "gift_pack",
          unlockedBy: user.uid, sourceTaskId: completionRef.id,
          unlockedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
      }
      return {...result, alreadyProcessed: false};
    });

    // Idempotent retry also retries fanout if a previous response was lost.
    // These are non-monetary, catalog-dependent reward eligibility documents.
    if (outcome.unlockedLevels?.length) {
      const present = await roomRef.collection("participants").get();
      const levels = outcome.unlockedLevels;
      const expiration = Timestamp.fromMillis(
        outcome.completedAtMillis + 30 * 24 * 60 * 60 * 1000);
      const membersPerBatch = Math.max(1, Math.floor(450 / levels.length));
      for (let offset = 0; offset < present.size; offset += membersPerBatch) {
        const batch = db.batch();
        for (const person of present.docs.slice(offset, offset + membersPerBatch)) {
          for (const level of levels) {
            const rewardId = `${roomId}_level_${level}`;
            batch.set(db.collection("users").doc(person.id)
              .collection("room_rewards").doc(rewardId), {
              userId: person.id, roomId, level,
              type: level === 5 ? "background_month" : "gift_pack",
              sourceRewardId: `level_${level}`,
              ...(level === 5 ? {expiresAt: expiration} : {}),
              grantedAt: FieldValue.serverTimestamp(),
            }, {merge: true});
          }
        }
        await batch.commit();
      }
    }
    return res.json({ok: true, ...outcome});
  } catch (error) {
    next(error);
  }
});

// Finance routes run only on the separately deployed authenticated backend.
registerWalletRoutes({app, db, authenticatedUser});
registerChatRoutes({app, db, authenticatedUser});

app.use((error, _req, res, _next) => {
  const providerMessage = String(error?.message || error || "");
  const aiQuotaUnavailable =
    /no credits remaining|insufficient_quota|exceeded.*quota|billing/i
      .test(providerMessage) &&
    (
      Number(error?.status) === 429 ||
      String(error?.name || "").toLowerCase().includes("ratelimit")
    );

  if (aiQuotaUnavailable) {
    console.error("WorldVoice AI provider unavailable:", providerMessage);
    return res.status(503).json({
      error: "WorldVoice AI service is temporarily unavailable.",
      code: "AI_SERVICE_UNAVAILABLE",
    });
  }

  const status =
    Number.isInteger(error?.status) && error.status >= 400
      ? error.status
      : 500;

  if (status >= 500) {
    console.error(error);
  }

  return res.status(status).json({
    error: status >= 500 ? "Server error." : String(error.message || error),
  });
});

app.listen(port, "0.0.0.0", () => {
  console.log(`WorldVoice room backend listening on port ${port}`);
  console.log(`Firebase project: ${firebaseProjectId || "auto"}`);
});