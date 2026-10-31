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

// Room authorization and Live authorization use separate Firestore namespaces.
export function tokenSessionCollection(channelName) {
  return channelName.startsWith("live_") ? "live_sessions" :
    channelName.startsWith("group_") ? "group_calls" :
      channelName.startsWith("call_") ? "calls" : "rooms";
}

// Firestore documents are fetched under the caller's signed Firebase token.
// The token signer additionally validates active attendance, not just a
// group membership list captured when the call began.
export function isAllowedGroupCallPublisher(fields, uid, channelName, role) {
  const members = fields?.memberIds?.arrayValue?.values || [];
  const joined = fields?.joinedIds?.arrayValue?.values || [];
  return fields?.status?.stringValue === "active" &&
    fields?.channelId?.stringValue === channelName &&
    members.some(item => item.stringValue === uid) &&
    joined.some(item => item.stringValue === uid) &&
    role === "publisher";
}

// Both call participants may publish only while a real, verified direct call
// is ringing or accepted. Firestore rules separately restrict who can read it.
export function isAllowedDirectCallPublisher(fields, uid, channelName, role) {
  return ["ringing", "accepted"].includes(fields?.status?.stringValue) &&
    fields?.channelId?.stringValue === channelName &&
    (fields?.callerId?.stringValue === uid ||
      fields?.recipientId?.stringValue === uid) &&
    role === "publisher";
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

  // Do not query legacy room documents for video Lives: their presence or
  // closed status must never shadow the real authenticated Live session.
  const collection = tokenSessionCollection(channelName);
  let session;
  try {
    session = await firestoreDocument({
      projectId: env.FIREBASE_PROJECT_ID,
      path: `${collection}/${collection === "group_calls"
        ? channelName.slice("group_".length)
        : collection === "calls" ? channelName.slice("call_".length)
          : channelName}`,
      idToken,
    });
  } catch (error) {
    return json({
      error: error?.status === 401
        ? "Firebase session is not authorized for Firestore."
        : "Cannot verify room or Live membership; check deployed Firestore rules.",
    }, error?.status === 401 ? 401 : 503);
  }

  // The app creates the Live record before joining Agora; never issue an
  // anonymous or unregistered Live token.
  if (!session?.fields) {
    return json({
      error: collection === "live_sessions"
        ? "Live session is not registered yet."
        : collection === "group_calls"
          ? "Group call is not active or available."
          : collection === "calls"
            ? "Private call is not active or available."
            : "Room is not found.",
    }, 404);
  }

  if (collection === "group_calls") {
    // Only a member who actively joined this group call may obtain an
    // Agora publisher token. Never rely on the client-supplied chat ID alone.
    const fields = session.fields;
    if (!isAllowedGroupCallPublisher(
      fields, uid, channelName, requestedRole,
    )) {
      return json({ error: "Join an active group call before publishing." }, 403);
    }
  } else if (collection === "calls") {
    if (!isAllowedDirectCallPublisher(
      session.fields, uid, channelName, requestedRole,
    )) {
      return json({ error: "Active direct call membership is required." }, 403);
    }
  } else if (collection === "rooms") {
    const room = session;
    if (room.fields.isOpen?.booleanValue !== true) {
      return json({ error: "Room is not open." }, 404);
    }
    const participant = await firestoreDocument({
      projectId: env.FIREBASE_PROJECT_ID,
      path: `rooms/${channelName}/participants/${encodeURIComponent(uid)}`,
      idToken,
    });
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
  } else {
    const fields = session.fields;
    const heartbeatMs = Date.parse(
      fields.hostHeartbeatAt?.timestampValue || "",
    );
    const fresh =
      fields.isLive?.booleanValue === true &&
      fields.channelId?.stringValue === channelName &&
      Number.isFinite(heartbeatMs) &&
      heartbeatMs > Date.now() - 60000;
    if (!fresh) {
      return json({ error: "Live session is not active." }, 404);
    }

    const hostId = fields.hostId?.stringValue || "";
    if (requestedRole === "publisher") {
      if (hostId !== uid) {
        const requestDoc = await firestoreDocument({
          projectId: env.FIREBASE_PROJECT_ID,
          path:
            `live_sessions/${channelName}/join_requests/${encodeURIComponent(uid)}`,
          idToken,
        });
        if (requestDoc?.fields?.status?.stringValue !== "accepted") {
          return json({
            error: "This viewer is not approved to publish Live video.",
          }, 403);
        }
      }
    } else if (hostId !== uid) {
      const viewerDoc = await firestoreDocument({
        projectId: env.FIREBASE_PROJECT_ID,
        path:
          `live_sessions/${channelName}/viewers/${encodeURIComponent(uid)}`,
        idToken,
      });
      if (viewerDoc?.fields?.uid?.stringValue !== uid) {
        return json({ error: "Join the Live before subscribing." }, 403);
      }
    }
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
  "/quiz/finish",
  "/room/tasks/status",
  "/room/tasks/claim",
  "/store/purchase",
  "/store/claim-reward",
  "/iap/verify",
  "/gift/send",
  "/wallet/settle",
  "/wallet/exchange",
  "/wallet/withdraw/quote",
  "/wallet/withdraw",
  "/web/checkout",
  "/web/stripe/webhook",
  "/chat/start",
  "/chat/message",
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
        tokenApiRevision: "2026-10-31.3",
        liveHostBootstrapSupported: true,
      }, ready ? 200 : 503);
    }
    if (auxiliaryRoutes.has(url.pathname) &&
        (request.method === "POST" ||
         (request.method === "GET" && url.pathname === "/room/tasks/status"))) {
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
