import { createHash } from "node:crypto";

import agoraToken from "agora-token";
import {
  AppStoreServerAPIClient,
  Environment as AppleEnvironment,
} from "@apple/app-store-server-library";
import express from "express";
import { applicationDefault, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { google } from "googleapis";
import OpenAI from "openai";
import { requireLiveEconomy, calculateGiftSettlement } from "./economy_policy.js";

const { RtcRole, RtcTokenBuilder } = agoraToken;

const firebaseProjectId = (
  process.env.FIREBASE_PROJECT_ID ||
  process.env.GOOGLE_CLOUD_PROJECT ||
  ""
).trim();
if (process.env.NODE_ENV === "production") {
  for (const key of ["AGORA_APP_ID", "AGORA_APP_CERTIFICATE"]) {
    if (!(process.env[key] || "").trim()) {
      throw new Error(`Cannot start production backend: missing ${key}`);
    }
  }
  if (!firebaseProjectId) {
    throw new Error("Cannot start production backend: missing FIREBASE_PROJECT_ID");
  }
}
if (getApps().length === 0) {
  initializeApp({
    credential: applicationDefault(),
    ...(firebaseProjectId ? { projectId: firebaseProjectId } : {}),
  });
}

const auth = getAuth();
const db = getFirestore();

const app = express();
app.disable("x-powered-by");
app.use(express.json({ limit: "32kb" }));

const port = Number(process.env.PORT || 8080);
const agoraAppId = (process.env.AGORA_APP_ID || "").trim();
const agoraCertificate = (process.env.AGORA_APP_CERTIFICATE || "").trim();
const openAiKey = (process.env.OPENAI_API_KEY || "").trim();
const teacherModel = (process.env.OPENAI_TEACHER_MODEL || "").trim();

const androidPackageName =
  (process.env.ANDROID_PACKAGE_NAME || "com.worldvoice.worldvoice").trim();
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
  userId,
  platform,
  receiptId,
  productId,
  catalogId,
  coins,
  purchasedAt,
}) {
  const receiptKey = createHash("sha256")
    .update(`${platform}:${receiptId}`)
    .digest("hex");
  const receiptRef = db.collection("iap_receipts").doc(receiptKey);
  const userRef = db.collection("users").doc(userId);

  return db.runTransaction(async (tx) => {
    const receiptSnap = await tx.get(receiptRef);
    if (receiptSnap.exists) {
      const existing = receiptSnap.data() || {};
      if (existing.userId !== userId) {
        const error = new Error("This store receipt was already used.");
        error.status = 409;
        throw error;
      }
      return {
        alreadyCredited: true,
        coins: Number(existing.coins || coins),
      };
    }

    tx.set(
      userRef,
      {
        coins: FieldValue.increment(coins),
        purchasedCoins: FieldValue.increment(coins),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    tx.set(receiptRef, {
      userId,
      platform,
      receiptId,
      productId,
      catalogId,
      coins,
      purchasedAt: purchasedAt || null,
      creditedAt: FieldValue.serverTimestamp(),
    });

    return {
      alreadyCredited: false,
      coins,
    };
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
    const participantRef = roomRef.collection("participants").doc(user.uid);

    const [roomSnap, participantSnap] = await Promise.all([
      roomRef.get(),
      participantRef.get(),
    ]);

    if (!roomSnap.exists || roomSnap.data()?.isOpen !== true) {
      return res.status(404).json({ error: "Room is not open." });
    }

    if (!participantSnap.exists) {
      return res.status(403).json({ error: "User is not a room participant." });
    }

    const participant = participantSnap.data() || {};
    if (requestedRole === "publisher" && !isStageRole(participant.role)) {
      return res.status(403).json({
        error: "This participant is not allowed to publish room audio.",
      });
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

app.post("/teacher-ai", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);

    requireEnv(openAiKey, "OPENAI_API_KEY");
    requireEnv(teacherModel, "OPENAI_TEACHER_MODEL");

    const roomId = String(req.body?.roomId || "").trim();
    const captionId = String(req.body?.captionId || "").trim();

    if (!roomId || !captionId) {
      return res.status(400).json({ error: "roomId and captionId are required." });
    }

    const roomRef = db.collection("rooms").doc(roomId);
    const participantRef = roomRef.collection("participants").doc(user.uid);
    const captionRef = roomRef.collection("captions").doc(captionId);
    const noteRef = roomRef.collection("teacher_ai_notes").doc(captionId);

    const [roomSnap, participantSnap, captionSnap, existingNote] =
      await Promise.all([
        roomRef.get(),
        participantRef.get(),
        captionRef.get(),
        noteRef.get(),
      ]);

    if (!roomSnap.exists || roomSnap.data()?.isOpen !== true) {
      return res.status(404).json({ error: "Room is not open." });
    }

    if (!participantSnap.exists) {
      return res.status(403).json({ error: "User is not in this room." });
    }

    if (!captionSnap.exists) {
      return res.status(404).json({ error: "Caption not found." });
    }

    if (existingNote.exists) {
      return res.json({ ok: true, cached: true });
    }

    const caption = captionSnap.data() || {};
    if (caption.userId !== user.uid) {
      return res.status(403).json({ error: "Caption owner mismatch." });
    }

    const text = String(caption.text || "").trim();
    const languageCode = String(caption.languageCode || "en").trim();
    const roomLanguageCode = String(
      req.body?.roomLanguageCode || roomSnap.data()?.languageCode || languageCode,
    ).trim();

    if (!text) {
      return res.status(400).json({ error: "Caption text is empty." });
    }

    const response = await openai.responses.create({
      model: teacherModel,
      store: false,
      instructions:
        "You are WorldVoice Teacher AI inside a live language-learning voice room. " +
        "Review only the provided transcript text. Do not claim to hear pronunciation audio. " +
        "If the sentence is natural and correct, correction must be an empty string. " +
        "If it needs improvement, give one concise corrected sentence. " +
        "pronunciationTip may contain one short text-based pronunciation tip only when useful. " +
        "Return only valid JSON with exactly these keys: correction, pronunciationTip.",
      input:
        `Target room language: ${roomLanguageCode}\n` +
        `Speaker transcript language: ${languageCode}\n` +
        `Transcript: ${text}`,
    });

    let result;
    try {
      result = JSON.parse(response.output_text || "{}");
    } catch {
      result = {};
    }

    const correction =
      typeof result.correction === "string"
        ? result.correction.trim().slice(0, 400)
        : "";
    const pronunciationTip =
      typeof result.pronunciationTip === "string"
        ? result.pronunciationTip.trim().slice(0, 240)
        : "";

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

    const roomRef = db.collection("rooms").doc(roomId);
    const participantRef = roomRef.collection("participants").doc(user.uid);
    const [roomSnap, participantSnap] = await Promise.all([
      roomRef.get(),
      participantRef.get(),
    ]);

    if (!roomSnap.exists || roomSnap.data()?.isOpen !== true) {
      return res.status(404).json({ error: "Room is not open." });
    }

    if (!participantSnap.exists) {
      return res.status(403).json({ error: "User is not in this room." });
    }

    const roomLanguageCode =
      requestedRoomLanguage ||
      String(roomSnap.data()?.languageCode || "en").trim() ||
      "en";

    const response = await openai.responses.create({
      model: teacherModel,
      store: false,
      instructions:
        "You are WorldVoice Teacher AI inside a live language-learning room. " +
        "Answer the member's language-learning question clearly and concisely. " +
        "The room target language is provided as context. " +
        "Reply in the same language as the member unless they explicitly ask to practice or receive an answer in another language. " +
        "When correcting a sentence, show the corrected form and a short explanation. " +
        "Do not claim to hear audio unless transcript text is explicitly provided.",
      input:
        `Target room language: ${roomLanguageCode}\n` +
        `Member question: ${prompt}`,
    });

    const answer = String(response.output_text || "").trim().slice(0, 2400);
    if (!answer) {
      return res.status(502).json({ error: "Teacher AI returned no answer." });
    }

    return res.json({
      ok: true,
      answer,
    });
  } catch (error) {
    next(error);
  }
});

app.post("/store/purchase", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);
    const itemId = String(req.body?.itemId || "").trim();

    if (!itemId) {
      return res.status(400).json({ error: "itemId is required." });
    }

    const itemRef = db.collection("room_shop_items").doc(itemId);
    const userRef = db.collection("users").doc(user.uid);

    const result = await db.runTransaction(async (tx) => {
      const itemSnap = await tx.get(itemRef);
      if (!itemSnap.exists) {
        const error = new Error("Store item not found.");
        error.status = 404;
        throw error;
      }

      const item = itemSnap.data() || {};
      if (item.active !== true || item.type !== "background") {
        const error = new Error("This background is not available.");
        error.status = 409;
        throw error;
      }

      const themeId = String(item.themeId || itemId).trim();
      const name = String(item.name || "WorldVoice Background").trim();
      const backgroundUrl = String(item.previewUrl || "").trim();
      const priceCoins = Number(item.priceCoins);
      const durationDays =
        item.durationDays == null ? null : Number(item.durationDays);

      if (
        !themeId ||
        !Number.isInteger(priceCoins) ||
        priceCoins < 0 ||
        (durationDays != null &&
          (!Number.isInteger(durationDays) || durationDays <= 0))
      ) {
        const error = new Error("Store item configuration is invalid.");
        error.status = 500;
        throw error;
      }

      const entitlementRef = userRef
        .collection("room_backgrounds")
        .doc(themeId);

      const [userSnap, entitlementSnap] = await Promise.all([
        tx.get(userRef),
        tx.get(entitlementRef),
      ]);

      const existing = entitlementSnap.data() || {};
      const existingExpiry = existing.expiresAt?.toDate?.() || null;
      const alreadyActive =
        entitlementSnap.exists &&
        (existingExpiry == null || existingExpiry.getTime() > Date.now());

      if (alreadyActive) {
        return {
          themeId,
          alreadyOwned: true,
          balance: Number(userSnap.data()?.coins || 0),
        };
      }

      const userData = userSnap.data() || {};
      const balance = Number(userData.coins || 0);
      if (!Number.isInteger(balance) || balance < priceCoins) {
        const error = new Error("NOT_ENOUGH_COINS");
        error.status = 409;
        throw error;
      }

      const expiresAt =
        durationDays == null
          ? null
          : Timestamp.fromMillis(
              Date.now() + durationDays * 24 * 60 * 60 * 1000,
            );

      tx.set(
        userRef,
        {
          coins: balance - priceCoins,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      tx.set(
        entitlementRef,
        {
          itemId,
          themeId,
          name,
          backgroundUrl,
          source: "purchase",
          priceCoins,
          purchasedAt: FieldValue.serverTimestamp(),
          ...(expiresAt ? { expiresAt } : {}),
        },
        { merge: true },
      );

      return {
        themeId,
        alreadyOwned: false,
        balance: balance - priceCoins,
      };
    });

    return res.json({ ok: true, ...result });
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
 * Unified gift contract for room/live/chat. Only room has a deployed, audited
 * membership model currently. Other contexts intentionally fail closed until
 * their permission checks and event streams are implemented.
 * Idempotency-Key is mandatory; clients reuse it for a checkout retry.
 */
app.post("/gift/send", async (req, res, next) => {
  try {
    const sender = await authenticatedUser(req);
    const {context, contextId, recipientId, giftId} = req.body || {};
    const quantity = Number(req.body?.quantity);
    const requestKey = String(req.headers["idempotency-key"] || "").trim();
    if (!["room", "live", "chat"].includes(context) ||
        !validChannelName(contextId) ||
        typeof recipientId !== "string" || !recipientId.trim() ||
        recipientId === sender.uid ||
        typeof giftId !== "string" ||
        !/^[A-Za-z0-9_-]{1,80}$/.test(giftId) ||
        !Number.isSafeInteger(quantity) || quantity <= 0 ||
        !/^[A-Za-z0-9_-]{12,100}$/.test(requestKey)) {
      return res.status(400).json({error: "Invalid gift request or idempotency key."});
    }
    // Live and chat lack completed server-verified participant ACLs for now.
    if (context !== "room") {
      return res.status(501).json({
        error: "Gifting in this context is not yet safely available.",
      });
    }
    const requestHash = createHash("sha256")
      .update(`${sender.uid}:${requestKey}`).digest("hex");
    const eventRef = db.collection("economy_gift_operations").doc(requestHash);
    const senderRef = db.collection("users").doc(sender.uid);
    const recipientRef = recipientId === "teacher_ai" ? null
      : db.collection("users").doc(recipientId);
    const inventoryRef = senderRef.collection("inventory")
      .doc(`gift__${giftId}`);
    const itemRef = db.collection("store_items").doc(`gift__${giftId}`);
    const roomRef = db.collection("rooms").doc(contextId);
    const senderMemberRef = roomRef.collection("participants").doc(sender.uid);
    const recipientMemberRef = recipientRef
      ? roomRef.collection("participants").doc(recipientId) : null;
    const configRef = db.collection("economy_config").doc("current");
    const giftEventRef = roomRef.collection("gifts").doc(requestHash);

    const outcome = await db.runTransaction(async (tx) => {
      // All reads before writes (Firestore transaction requirement).
      const refs = [eventRef, configRef, itemRef, roomRef, senderMemberRef,
        senderRef, inventoryRef, ...(recipientRef
          ? [recipientMemberRef, recipientRef] : [])];
      const snapshots = await Promise.all(refs.map(ref => tx.get(ref)));
      const [existing, configSnap, itemSnap, roomSnap, senderMember,
        senderSnap, freeGiftSnap] = snapshots;
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
      if (roomSnap.data()?.isOpen !== true || !senderMember.exists ||
          (recipientMemberRef && !snapshots[7].exists)) {
        throw Object.assign(new Error("Room membership is required."), {status: 403});
      }
      const config = requireLiveEconomy(configSnap.data());
      const item = itemSnap.data();
      const price = Number(item?.priceCoins);
      if (!itemSnap.exists || item.type !== "gift" || item.active !== true ||
          !Number.isSafeInteger(price) || price <= 0) {
        throw Object.assign(new Error("This gift is unavailable."), {status: 404});
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
      const recipientData = recipientRef ? snapshots[8].data() || {} : null;
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
      tx.set(senderRef, {
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
        tx.set(recipientRef, {
          diamondsPending: receiverAfter,
          giftReceivedPoints: FieldValue.increment(amounts.chargedCoins),
          updatedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
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
        senderId: sender.uid,
        senderName: String(senderData.displayName || "WorldVoice user"),
        recipientId, recipientName: recipientRef
          ? String(recipientData.displayName || "WorldVoice member")
          : "Teacher AI",
        giftId, points: amounts.chargedCoins, quantity,
        animationUrl: item.animationUrl || null,
        createdAt: FieldValue.serverTimestamp(),
      });
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

app.post("/quiz/finish", async (req, res, next) => {
  try {
    const user = await authenticatedUser(req);
    const roomId = String(req.body?.roomId || "").trim();

    if (!roomId) {
      return res.status(400).json({ error: "roomId is required." });
    }

    const roomRef = db.collection("rooms").doc(roomId);
    const roomSnap = await roomRef.get();

    if (!roomSnap.exists || roomSnap.data()?.isOpen !== true) {
      return res.status(404).json({ error: "Room is not open." });
    }

    if (roomSnap.data()?.hostId !== user.uid) {
      return res.status(403).json({ error: "Only the host can finish the quiz." });
    }

    const answersSnap = await roomRef.collection("quiz_answers").get();
    const roomData = roomSnap.data() || {};
    const quiz = roomData.quiz || {};
    const correctIndex = Number(quiz.correctIndex);

    if (!Number.isInteger(correctIndex)) {
      return res.status(409).json({ error: "No active quiz." });
    }

    const correctAnswers = answersSnap.docs
      .map((doc) => ({ id: doc.id, ...doc.data() }))
      .filter((answer) => Number(answer.optionIndex) === correctIndex)
      .sort((a, b) => {
        const aTime = a.answeredAt?.toMillis?.() || Number.MAX_SAFE_INTEGER;
        const bTime = b.answeredAt?.toMillis?.() || Number.MAX_SAFE_INTEGER;
        return aTime - bTime;
      })
      .slice(0, 3);

    const winners = correctAnswers.map((answer, index) => ({
      place: index + 1,
      userId: String(answer.userId || answer.id),
      displayName: String(answer.displayName || "WorldVoice user"),
      prizeCoins: index === 0 ? 5 : 0,
    }));

    const transactionResult = await db.runTransaction(async (tx) => {
      const latestRoom = await tx.get(roomRef);
      const latestQuiz = latestRoom.data()?.quiz || {};

      if (latestQuiz.rewardedAt != null) {
        return {
          alreadyFinished: true,
          winners: Array.isArray(latestQuiz.winners)
            ? latestQuiz.winners
            : [],
        };
      }

      if (winners.length > 0) {
        const winnerRef = db.collection("users").doc(winners[0].userId);
        const winnerSnap = await tx.get(winnerRef);
        const balance = Number(winnerSnap.data()?.coins || 0);
        tx.set(
          winnerRef,
          {
            coins: balance + 5,
            quizCoinsEarned: FieldValue.increment(5),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }

      tx.set(
        roomRef,
        {
          "quiz.revealed": true,
          "quiz.winners": winners,
          "quiz.firstPrizeCoins": 5,
          "quiz.rewardedAt": FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      return {
        alreadyFinished: false,
        winners,
      };
    });

    return res.json({ ok: true, ...transactionResult });
  } catch (error) {
    next(error);
  }
});

app.use((error, _req, res, _next) => {
  const status =
    Number.isInteger(error?.status) && error.status >= 400
      ? error.status
      : 500;

  if (status >= 500) {
    console.error(error);
  }

  res.status(status).json({
    error: status >= 500 ? "Server error." : String(error.message || error),
  });
});

app.listen(port, "0.0.0.0", () => {
  console.log(`WorldVoice room backend listening on port ${port}`);
  console.log(`Firebase project: ${firebaseProjectId || "auto"}`);
});
