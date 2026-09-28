import { createHash } from "node:crypto";
import agoraToken from "agora-token";
import { createRemoteJWKSet, jwtVerify } from "jose";

const { RtcRole, RtcTokenBuilder } = agoraToken;
const firebasePublicKeys = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/" +
      "securetoken@system.gserviceaccount.com",
  ),
);

function json(payload, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}

export function validChannelName(value) {
  return (
    typeof value === "string" &&
    value.length > 0 &&
    value.length < 64 &&
    /^[A-Za-z0-9_]+$/.test(value)
  );
}

export function agoraUidForFirebaseUid(uid) {
  const digest = createHash("sha256").update(uid).digest();
  return digest.readUInt32BE(0) || 1;
}

function configured(env) {
  return /^[a-fA-F0-9]{32}$/.test((env.AGORA_APP_ID || "").trim()) &&
    (env.AGORA_APP_CERTIFICATE || "").trim().length > 0 &&
    (env.FIREBASE_PROJECT_ID || "").trim().length > 0;
}

async function firebaseUserId(idToken, projectId) {
  const { payload } = await jwtVerify(idToken, firebasePublicKeys, {
    algorithms: ["RS256"],
    audience: projectId,
    issuer: `https://securetoken.google.com/${projectId}`,
    clockTolerance: 5,
  });
  if (
    typeof payload.sub !== "string" ||
    payload.sub.length === 0 ||
    payload.sub.length > 128 ||
    !Number.isInteger(payload.auth_time) ||
    payload.auth_time > Math.floor(Date.now() / 1000)
  ) {
    throw new Error("Invalid Firebase subject or authentication time");
  }
  // The signature and expiry are validated by jose. Firebase user disablement
  // and token revocation cannot be checked by a standalone JWT verifier;
  // Firestore rules and up-to-date membership checks are required on each call.
  return payload.sub;
}

async function firestoreDocument({ projectId, path, idToken }) {
  const url = `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(projectId)}/databases/(default)/documents/${path}`;
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${idToken}` },
    signal: AbortSignal.timeout(10000),
  });
  if (response.status === 404) return null;
  if (!response.ok) {
    // Do not reveal external API output, token or project internals.
    const error = new Error("Room membership could not be verified by Firestore");
    error.status = response.status === 401 ? 401 : 503;
    throw error;
  }
  return response.json();
}

async function agoraTokenForUser(request, env) {
  if (!configured(env)) {
    return json({ error: "Agora worker configuration is incomplete." }, 503);
  }
  const bearer = request.headers.get("authorization") || "";
  if (!bearer.startsWith("Bearer ") || bearer.length > 10000) {
    return json({ error: "Sign in to WorldVoice first." }, 401);
  }
  const idToken = bearer.slice(7).trim();
  if (!idToken) return json({ error: "Missing Firebase ID token." }, 401);
  let input;
  try {
    if (Number(request.headers.get("content-length") || 0) > 4096) {
      return json({ error: "Request is too large." }, 413);
    }
    input = await request.json();
  } catch (_) {
    return json({ error: "Expected valid JSON request body." }, 400);
  }
  const channelName = input?.channelName;
  const requestedRole = input?.role === "publisher" ? "publisher" : "subscriber";
  if (!validChannelName(channelName)) {
    return json({ error: "Invalid channelName." }, 400);
  }

  let uid;
  try {
    uid = await firebaseUserId(idToken, env.FIREBASE_PROJECT_ID);
  } catch (_) {
    return json({ error: "Firebase sign-in expired or invalid. Sign in again." }, 401);
  }

  const roomPath = `rooms/${channelName}`;
  const participantPath = `rooms/${channelName}/participants/${encodeURIComponent(uid)}`;
  let room;
  let participant;
  try {
    [room, participant] = await Promise.all([
      firestoreDocument({
        projectId: env.FIREBASE_PROJECT_ID,
        path: roomPath,
        idToken,
      }),
      firestoreDocument({
        projectId: env.FIREBASE_PROJECT_ID,
        path: participantPath,
        idToken,
      }),
    ]);
  } catch (error) {
    return json({
      error: error?.status === 401
        ? "Firebase session is not authorized for Firestore."
        : "Cannot verify room membership; check deployed Firestore rules.",
    }, error?.status === 401 ? 401 : 503);
  }
  if (room?.fields?.isOpen?.booleanValue !== true) {
    return json({ error: "Room is not open." }, 404);
  }
  if (!participant?.fields) {
    return json({ error: "User is not a room participant." }, 403);
  }
  if (participant.fields.kicked?.booleanValue === true) {
    return json({ error: "Participant was removed from the room." }, 403);
  }
  const role = participant.fields.role?.stringValue;
  if (requestedRole === "publisher" &&
      !["host", "coHost", "speaker", "vipSeat"].includes(role)) {
    return json({ error: "Only stage members can publish room audio." }, 403);
  }

  const agoraUid = agoraUidForFirebaseUid(uid);
  const ttlSeconds = 60 * 60;
  const token = RtcTokenBuilder.buildTokenWithUid(
    env.AGORA_APP_ID,
    env.AGORA_APP_CERTIFICATE,
    channelName,
    agoraUid,
    requestedRole === "publisher" ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER,
    ttlSeconds,
    ttlSeconds,
  );
  return json({ token, uid: agoraUid, expiresIn: ttlSeconds });
}

// Optional: all remaining routes can be enabled later without rebuilding the
// Android APK by setting AUX_BACKEND_URL to a deployed full Node backend.
// Only known WorldVoice endpoints are forwarded; no arbitrary proxying.
const auxiliaryRoutes = new Set([
  "/teacher-ai",
  "/teacher-ai/ask",
  "/quiz/start",
  "/quiz/answer",
  "/quiz/finish",
  "/store/purchase",
  "/store/claim-reward",
  "/iap/verify",
]);

async function forwardAuxiliaryRequest(request, env) {
  const raw = (env.AUX_BACKEND_URL || "").trim();
  if (!raw) {
    return json({
      error: "This feature is not yet enabled on the free test backend.",
    }, 503);
  }
  const base = URL.canParse(raw) ? new URL(raw) : null;
  if (base?.protocol !== "https:" || base.username || base.password ||
      base.search || base.hash) {
    return json({ error: "Auxiliary backend needs an HTTPS URL." }, 503);
  }
  try {
    const original = new URL(request.url);
    const target = new URL(original.pathname + original.search, base.origin);
    const response = await fetch(new Request(target, request));
    // Forward only the backend's authenticated response and status.
    return response;
  } catch (_) {
    return json({
      error: "Optional backend is waking up or currently unavailable. Try again.",
    }, 503);
  }
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === "GET" && url.pathname === "/health") {
      const ready = configured(env);
      return json({
        ok: ready,
        service: "worldvoice-agora-token-worker",
      }, ready ? 200 : 503);
    }
    if (request.method === "POST" && auxiliaryRoutes.has(url.pathname)) {
      return forwardAuxiliaryRequest(request, env);
    }
    if (request.method !== "POST" || url.pathname !== "/agora/token") {
      return json({ error: "Endpoint not found." }, 404);
    }
    try {
      return await agoraTokenForUser(request, env);
    } catch (_) {
      return json({ error: "Token service could not process the request." }, 503);
    }
  },
};
