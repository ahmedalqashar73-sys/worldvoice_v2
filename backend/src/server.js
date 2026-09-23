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

const { RtcRole, RtcTokenBuilder } = agoraToken;

if (getApps().length === 0) {
  initializeApp({
    credential: applicationDefault(),
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
  } catch {
    const error = new Error("Invalid or expired Firebase authorization token.");
    error.status = 401;
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
});
