/**
 * One-account owner enrollment, for the Firebase project administrator.
 *
 * Read-only preview:
 * node scripts/enroll-verified-owner.mjs --project worldvoice-37896 \
 *   --uid FIREBASE_AUTH_UID --email VERIFIED_GOOGLE_EMAIL
 *
 * Explicit one-account apply (requires privileged ADC/service-account IAM):
 * node scripts/enroll-verified-owner.mjs --project worldvoice-37896 \
 *   --uid FIREBASE_AUTH_UID --email VERIFIED_GOOGLE_EMAIL \
 *   --apply --confirm-project worldvoice-37896 --confirm-uid FIREBASE_AUTH_UID
 *
 * This script never grants coins directly. The existing server awards the
 * monthly 10,000 coins once, using its unique month ledger, after sign-in.
 * It never enables purchases or alters economy_config/current.
 */
import {applicationDefault, initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore, FieldValue, Timestamp} from "firebase-admin/firestore";
import {ownerWalletFromLegacyProfile} from "../src/owner_coin_policy.js";
import {requirePrivateWallet} from "../src/wallet_store.js";

const args = process.argv.slice(2);
const option = name => {
  const i = args.indexOf(name);
  return i < 0 ? "" : String(args[i + 1] || "").trim();
};
const project = option("--project");
const uid = option("--uid");
const email = option("--email").toLowerCase();
const apply = args.includes("--apply");
if (project !== "worldvoice-37896" ||
    !/^[A-Za-z0-9_-]{6,128}$/.test(uid) ||
    !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
  throw new Error("Supply the exact project, Firebase Auth UID and Google email.");
}
if (apply && (option("--confirm-project") !== project ||
    option("--confirm-uid") !== uid)) {
  throw new Error("Apply requires matching --confirm-project and --confirm-uid.");
}
initializeApp({credential: applicationDefault(), projectId: project});
const auth = getAuth();
const db = getFirestore();
const identity = await auth.getUser(uid);
if (identity.disabled || identity.emailVerified !== true ||
    String(identity.email || "").trim().toLowerCase() !== email) {
  throw new Error("Identity must be enabled, email-verified and match Firebase UID.");
}
const profileRef = db.collection("users").doc(uid);
const walletRef = profileRef.collection("private").doc("wallet");
const adminRef = db.collection("admins").doc(uid);
const existingUserWithEmail = await auth.getUserByEmail(email);
if (existingUserWithEmail.uid !== uid) {
  throw new Error("The Firebase email resolves to a different UID.");
}
const [profileSnap, walletSnap, adminSnap, pastOperations] = await Promise.all([
  profileRef.get(),
  walletRef.get(),
  adminRef.get(),
  profileRef.collection("wallet_transactions").limit(1).get(),
]);
if (!profileSnap.exists) throw new Error("Matching profile does not exist.");
const priorAdmin = adminSnap.data() || {};
if (adminSnap.exists &&
    (priorAdmin.uid != null && priorAdmin.uid !== uid ||
     priorAdmin.email != null &&
      String(priorAdmin.email).trim().toLowerCase() !== email)) {
  throw new Error("Conflicting existing protected admin record; stop for review.");
}
const hasWallet = walletSnap.exists;
if (hasWallet) requirePrivateWallet(walletSnap);
else if (!pastOperations.empty) {
  throw new Error("Existing ledger without private wallet: manual reconciliation required.");
}
const proposedWallet = hasWallet ? null :
  ownerWalletFromLegacyProfile(profileSnap.data() || {});
console.log(JSON.stringify({
  targetMatched: true, emailVerified: true,
  protectedAdminAlreadyExists: adminSnap.exists,
  privateWalletExists: hasWallet,
  pendingWalletCreation: !hasWallet,
  mode: apply ? "APPLY" : "PREVIEW_ONLY",
}, null, 2));
if (!apply) process.exit(0);

await db.runTransaction(async tx => {
  const [currentProfile, currentWallet, currentAdmin, past] = await Promise.all([
    tx.get(profileRef),
    tx.get(walletRef),
    tx.get(adminRef),
    tx.get(profileRef.collection("wallet_transactions").limit(1)),
  ]);
  if (!currentProfile.exists) throw new Error("Profile vanished during enrollment.");
  const current = currentAdmin.data() || {};
  if (currentAdmin.exists &&
      (current.uid != null && current.uid !== uid ||
       current.email != null &&
         String(current.email).trim().toLowerCase() !== email)) {
    throw new Error("Conflicting protected admin record.");
  }
  if (!currentWallet.exists) {
    if (!past.empty) {
      throw new Error("Cannot create wallet over pre-existing monetary history.");
    }
    const initial = ownerWalletFromLegacyProfile(currentProfile.data() || {});
    tx.create(walletRef, {
      ...initial,
      migrationSource: "verified_owner_enrollment",
      stagedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  } else {
    requirePrivateWallet(currentWallet);
  }
  tx.set(adminRef, {
    uid, email, role: "super_admin", active: true,
    permissions: ["view_visitors", "manage_rooms", "enter_private_rooms",
      "manage_vip", "manage_store", "manage_moderators",
      "send_announcements", "send_coins", "change_country"],
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  tx.set(profileRef, {
    isAdmin: true, adminSource: "owner_enrollment_verified",
    adminUpdatedAt: FieldValue.serverTimestamp(),
    isVip: true, vipSource: "owner_enrollment_verified",
    vipUpdatedAt: FieldValue.serverTimestamp(),
    vipExpiresAt: Timestamp.fromDate(new Date("2099-12-31T23:59:59Z")),
  }, {merge: true});
});
const fresh = await auth.getUser(uid);
await auth.setCustomUserClaims(uid, {
  ...(fresh.customClaims || {}),
  admin: true, economyAdmin: true, worldVoiceAdmin: true,
});
console.log("Owner enrollment completed for exactly one verified account.");
console.log("Reauthenticate in the app to obtain a fresh Firebase ID token.");
console.log("Monthly grant is server-ledger controlled and was NOT applied by this script.");
