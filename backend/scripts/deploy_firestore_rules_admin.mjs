// CI fallback for Firebase CLI when the service account lacks the optional
// Service Usage Viewer IAM permission. Uses Firebase's supported Admin SDK
// Security Rules API to publish the same repository's Firestore rules file.
// Never logs credential contents; never changes indexes or application data.
import {readFileSync} from "node:fs";
import {resolve} from "node:path";
import {cert, getApps, initializeApp} from "firebase-admin/app";
import {getSecurityRules} from "firebase-admin/security-rules";

const projectId = "worldvoice-37896";
const filename = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (!filename) {
  throw new Error("Missing GOOGLE_APPLICATION_CREDENTIALS in CI.");
}
const serviceAccount = JSON.parse(readFileSync(filename, "utf8"));
if (serviceAccount.project_id !== projectId) {
  throw new Error("Refusing to deploy rules using a different Firebase project.");
}
if (getApps().length === 0) {
  initializeApp({
    credential: cert(serviceAccount),
    projectId,
  });
}
const source = readFileSync(resolve("..", "firestore.rules"), "utf8");
if (!source.includes("match /live_sessions/{liveId}") ||
    !source.includes("'bubbleId'") ||
    !source.includes("match /messages/{messageId}")) {
  throw new Error("Expected WorldVoice Live message access rules are missing.");
}
try {
  const release = await getSecurityRules().releaseFirestoreRulesetFromSource(source);
  console.log("Firestore rules published to:", projectId);
  console.log("Published rules release:", String(release?.name || "cloud.firestore"));
} catch (error) {
  if (/permission|denied|403/i.test(String(error?.message ?? ""))) {
    console.error(
      "::error title=Firebase IAM authorization required::" +
      "Firestore rules were NOT published to worldvoice-37896. " +
      "Grant the existing GitHub FIREBASE_SERVICE_ACCOUNT_JSON service account " +
      "roles/firebaserules.admin (firebaserules.rulesets.create and releases.update). " +
      "The Firebase CLI also needs roles/serviceusage.serviceUsageViewer. " +
      "Grant roles/datastore.indexAdmin for the delivery TTL setup; then rerun " +
      "the existing Deploy Firestore Rules workflow on main. No app or database copy is needed."
    );
    process.exitCode = 1;
  } else {
    throw error;
  }
}
