/**
 * Read-only production readiness audit, invoked in GitHub Actions with
 * FIREBASE_SERVICE_ACCOUNT_JSON. Prints NO emails, UIDs, balances or tokens.
 * Does not grant roles, modify any wallet or enable the economy.
 */
import {applicationDefault, initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";

const project = "worldvoice-37896";
initializeApp({credential: applicationDefault(), projectId: project});
const auth = getAuth();
const db = getFirestore();
const configSnap = await db.doc("economy_config/current").get();
const config = configSnap.data() || {};

const profiles = await db.collection("users")
  .where("isAdmin", "==", true).limit(30).get();
const checks = {
  adminProfilesFound: profiles.size,
  scannedLimit: 30,
  matchedLegacyAllowlist: 0,
  signedOwnerClaims: 0,
  verifiedIdentityButNoOwnerProof: 0,
  unverifiedEmail: 0,
  missingPrivateWallet: 0,
  presentPrivateWallet: 0,
  activeServerAdmin: 0,
};
for (const profile of profiles.docs) {
  const [identity, walletSnap, adminSnap] = await Promise.all([
    auth.getUser(profile.id).catch(() => null),
    profile.ref.collection("private").doc("wallet").get(),
    db.collection("admins").doc(profile.id).get(),
  ]);
  if (walletSnap.exists) checks.presentPrivateWallet++;
  else checks.missingPrivateWallet++;
  const admin = adminSnap.data() || {};
  if (admin.active === true && admin.role === "super_admin") {
    checks.activeServerAdmin++;
  }
  const claims = identity?.customClaims || {};
  if (!identity?.emailVerified) {
    checks.unverifiedEmail++;
  } else {
    if ((identity.email || "").trim().toLowerCase() ===
        "ahmedabdalkarim19@gmail.com") checks.matchedLegacyAllowlist++;
    if (claims.admin === true && claims.economyAdmin === true &&
        claims.worldVoiceAdmin === true) {
      checks.signedOwnerClaims++;
    } else if ((identity.email || "").trim()) {
      checks.verifiedIdentityButNoOwnerProof++;
    }
  }
}
console.log(JSON.stringify({
  project,
  configPresent: configSnap.exists,
  economyEnabled: config.enabled === true,
  privateWalletCutoverVerified: config.privateWalletCutoverVerified === true,
  publicProfileRulesVerified: config.publicProfileRulesVerified === true,
  hasPositiveCoinConversion: Number(config.coinsPerUsd) > 0,
  hasPositiveDiamondValuation: Number(config.diamondUsdValue) > 0,
  ownerReadiness: checks,
}, null, 2));
