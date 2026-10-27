// Dedicated WorldVoice Stories API. Isolated from Teacher AI, room economy,
// voice rooms, and Live. Shares the existing Firebase Auth and Firestore data.
import express from "express";
import {applicationDefault, cert, getApps, initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";

import {registerStoryRoutes} from "./story_routes.js";
import {registerStoryInteractionRoutes} from "./story_interactions_routes.js";

const projectId = String(
  process.env.FIREBASE_PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT || "",
).trim();
if (process.env.NODE_ENV === "production" && !projectId) {
  throw new Error("FIREBASE_PROJECT_ID is required for WorldVoice Stories.");
}

if (getApps().length === 0) {
  const rawCredentials = String(process.env.FIREBASE_SERVICE_ACCOUNT_JSON || "").trim();
  let credential = applicationDefault();
  if (rawCredentials) {
    let serviceAccount;
    try {
      serviceAccount = JSON.parse(rawCredentials);
    } catch {
      throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON must contain valid JSON.");
    }
    credential = cert(serviceAccount);
  }
  initializeApp({
    credential,
    ...(projectId ? {projectId} : {}),
  });
}

const auth = getAuth();
const db = getFirestore();
const app = express();
app.disable("x-powered-by");

// Only small JSON bodies are needed for Close Friends and Story actions.
// Uploads use the route's own image/video binary parser (80 MB max).
app.use(express.json({limit: "128kb"}));

async function authenticatedUser(req) {
  const authorization = String(req.headers.authorization || "");
  const token = authorization.startsWith("Bearer ")
    ? authorization.slice("Bearer ".length).trim()
    : "";
  if (!token) {
    const error = new Error("Missing Firebase authorization token.");
    error.status = 401;
    throw error;
  }
  try {
    return await auth.verifyIdToken(token, true);
  } catch (cause) {
    const code = String(cause?.code || "");
    const userIssue = new Set([
      "auth/id-token-expired",
      "auth/id-token-revoked",
      "auth/invalid-id-token",
      "auth/argument-error",
      "auth/user-disabled",
      "auth/user-not-found",
    ]).has(code);
    console.warn("WorldVoice Stories Firebase auth rejected:", code);
    const error = new Error(userIssue
      ? "Your login has expired. Sign in again."
      : "Stories authentication service is unavailable.");
    error.status = userIssue ? 401 : 503;
    throw error;
  }
}

app.get("/health", (_req, res) => {
  res.json({ok: true, service: "worldvoice-stories"});
});

registerStoryRoutes({app, authenticatedUser, db, projectId});
registerStoryInteractionRoutes({app, authenticatedUser, db});

app.use((error, _req, res, _next) => {
  if (error?.code === "STORY_STORAGE_NOT_READY") {
    return res.status(503).json({
      ok: false,
      code: "STORY_STORAGE_NOT_READY",
      error: "Story media storage is unavailable. Configure CLOUDINARY_URL in this Render service.",
    });
  }
  const status = Number.isInteger(error?.status) &&
      error.status >= 400 && error.status <= 599
    ? error.status
    : 500;
  if (status >= 500) {
    console.error("Stories API error:", error?.code || error?.message || error);
  }
  res.status(status).json({
    ok: false,
    error: status >= 500 ? "Stories service error." :
      String(error?.message || "Request failed."),
  });
});

const port = Number(process.env.PORT || 8080);
app.listen(port, "0.0.0.0", () => {
  console.info(`WorldVoice Stories listening on port ${port}; Firebase project: ${projectId || "auto"}`);
});
