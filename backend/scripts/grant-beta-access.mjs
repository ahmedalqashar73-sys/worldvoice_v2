import {applicationDefault, getApps, initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {FieldValue, getFirestore} from "firebase-admin/firestore";

function arg(name) {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : "";
}

const apply = process.argv.includes("--apply");
const allVip = process.argv.includes("--all-vip");
const projectId = arg("--project").trim();
const confirmedProject = arg("--confirm-project").trim();
const adminEmail = arg("--admin-email").trim().toLowerCase();
const adminCoins = Number(arg("--admin-coins") || "0");

if (!projectId) throw new Error("--project is required.");
if (!apply) throw new Error("Preview-only is not supported for this mutating beta access script. Pass --apply.");
if (confirmedProject !== projectId) {
  throw new Error("--confirm-project must exactly match --project.");
}
if (!allVip) throw new Error("Pass --all-vip to confirm that every current Auth user should receive VIP.");
if (!adminEmail || !adminEmail.includes("@")) {
  throw new Error("--admin-email is required.");
}
if (!Number.isSafeInteger(adminCoins) || adminCoins < 0) {
  throw new Error("--admin-coins must be a non-negative safe integer.");
}

if (getApps().length === 0) {
  initializeApp({
    credential: applicationDefault(),
    projectId,
  });
}

const auth = getAuth();
const db = getFirestore();
const users = [];
let pageToken;
do {
  const page = await auth.listUsers(1000, pageToken);
  users.push(...page.users);
  pageToken = page.pageToken;
} while (pageToken);

console.log(`Firebase Auth users found: ${users.length}`);

let adminUser = null;
for (const user of users) {
  const email = (user.email || "").trim().toLowerCase();
  if (email === adminEmail) adminUser = user;

  await db.collection("users").doc(user.uid).set({
    isVip: true,
    vipSource: "friends_beta",
    vipUpdatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
}

if (!adminUser) {
  throw new Error("Admin email was not found in Firebase Authentication.");
}

const claims = adminUser.customClaims || {};
await auth.setCustomUserClaims(adminUser.uid, {
  ...claims,
  admin: true,
  economyAdmin: true,
  worldVoiceAdmin: true,
});

const userRef = db.collection("users").doc(adminUser.uid);
const walletRef = userRef.collection("private").doc("wallet");
const transactionRef =
  userRef.collection("wallet_transactions").doc("friends_beta_admin_grant_v1");

await db.runTransaction(async tx => {
  const [profileSnap, walletSnap, oldGrant] = await Promise.all([
    tx.get(userRef),
    tx.get(walletRef),
    tx.get(transactionRef),
  ]);

  tx.set(userRef, {
    isVip: true,
    isAdmin: true,
    adminSource: "friends_beta",
    vipSource: "friends_beta",
    vipUpdatedAt: FieldValue.serverTimestamp(),
    adminUpdatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  if (oldGrant.exists || adminCoins === 0) return;

  const profile = profileSnap.data() || {};
  const wallet = walletSnap.data() || {};
  const before = Number(wallet.coins ?? profile.coins ?? 0);
  if (!Number.isSafeInteger(before) || before < 0 ||
      !Number.isSafeInteger(before + adminCoins)) {
    throw new Error("Admin wallet coins require reconciliation before the beta grant.");
  }

  tx.set(walletRef, {
    coins: before + adminCoins,
    diamonds: Number(wallet.diamonds ?? profile.diamonds ?? 0) || 0,
    diamondsPending: Number(wallet.diamondsPending ?? profile.diamondsPending ?? 0) || 0,
    diamondsReserved: Number(wallet.diamondsReserved ?? 0) || 0,
    walletDebtCoins: Number(wallet.walletDebtCoins ?? 0) || 0,
    walletFrozen: wallet.walletFrozen === true,
    payoutFrozen: wallet.payoutFrozen === true,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  tx.create(transactionRef, {
    type: "friends_beta_admin_grant",
    amount: adminCoins,
    currency: "coins",
    balanceBefore: before,
    balanceAfter: before + adminCoins,
    source: "friends_beta",
    createdAt: FieldValue.serverTimestamp(),
  });
});

console.log(`VIP enabled for ${users.length} current Auth user(s).`);
console.log(`Admin enabled for: ${adminEmail}`);
console.log(adminCoins > 0
  ? `One-time admin coin grant requested: ${adminCoins}`
  : "No admin coin grant requested.");
