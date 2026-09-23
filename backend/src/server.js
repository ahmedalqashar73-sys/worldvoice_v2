import { createHash } from "node:crypto";

import agoraToken from "agora-token";
import express from "express";
import { applicationDefault, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
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

const openai = openAiKey ? new OpenAI({ apiKey: openAiKey }) : null;

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
    /^[A-Za-z0-9 !#$%&()+\-:;<=>?@[\]^_{}|~,.]+$/.test(value)
  );
}

function isStageRole(role) {
  return ["host", "coHost", "speaker", "vipSeat"].includes(role);
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
