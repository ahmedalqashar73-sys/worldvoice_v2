/**
 * STAGING ONLY: create sanitized public_profiles and private wallet snapshots.
 * Defaults to a read-only dry run. Never removes legacy users fields, deploys
 * rules, enables checkout, changes a balance, or overwrites an existing wallet.
 *
 * First: export/backup Firestore; authorize Google ADC service account.
 * node scripts/prepare-wallet-privacy.mjs --project YOUR_STAGING_PROJECT
 * node scripts/prepare-wallet-privacy.mjs --project YOUR_STAGING_PROJECT --apply
 */
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {getFirestore, FieldPath} from "firebase-admin/firestore";
import {
  hasPrivateWalletFields, toPrivateWallet, toPublicProfile,
  walletCopyMatches,
} from "../src/profile_privacy.js";

const args = process.argv.slice(2);
const p = args.indexOf("--project");
const projectId = p >= 0 ? args[p + 1] : null;
if (!projectId || !/^[a-z][a-z0-9-]+$/.test(projectId)) {
  throw new Error("Specify an explicit Firebase STAGING --project ID.");
}
const apply = args.includes("--apply");
if (apply && !args.includes("--backup-confirmed")) {
  throw new Error("--apply requires a verified backup: --backup-confirmed.");
}
if (apply && !args.includes("--staging-confirmed")) {
  throw new Error("--apply requires --staging-confirmed (never use in production).");
}
const maxUsersIndex = args.indexOf("--limit");
const maxUsers = maxUsersIndex === -1 ? Number.MAX_SAFE_INTEGER
  : Number(args[maxUsersIndex + 1]);
if (!Number.isSafeInteger(maxUsers) || maxUsers < 1) {
  throw new Error("--limit must be a positive integer.");
}
initializeApp({credential: applicationDefault(), projectId});
const db = getFirestore();
const stats = {scanned: 0, eligible: 0, walletCreated: 0,
  publicProfileCreated: 0, walletAlreadyExists: 0,
  publicProfileAlreadyExists: 0, missingUser: 0, conflicts: 0};
let previous;
while (stats.scanned < maxUsers) {
  let query = db.collection("users").orderBy(FieldPath.documentId())
    .limit(Math.min(100, maxUsers - stats.scanned));
  if (previous) query = query.startAfter(previous);
  const page = await query.get();
  if (page.empty) break;
  for (const doc of page.docs) {
    previous = doc;
    stats.scanned += 1;
    const data = doc.data();
    if (!hasPrivateWalletFields(data)) continue;
    stats.eligible += 1;
    const walletRef = doc.ref.collection("wallet").doc("private");
    const publicRef = db.collection("public_profiles").doc(doc.id);
    if (!apply) continue;
    try {
      const outcome = await db.runTransaction(async tx => {
        const [fresh, existingWallet, existingPublic] = await Promise.all([
          tx.get(doc.ref), tx.get(walletRef), tx.get(publicRef),
        ]);
        if (!fresh.exists) return {missingUser: 1};
        const walletData = toPrivateWallet(doc.id, fresh.data());
        const publicData = toPublicProfile(doc.id, fresh.data());
        if (existingWallet.exists &&
            !walletCopyMatches(existingWallet.data(), walletData)) {
          // A previous migration or live financial writes changed values.
          // Do NOT overwrite or guess which balance is authoritative.
          throw new Error("PRIVATE_WALLET_CONFLICT");
        }
        if (!existingWallet.exists) {
          tx.create(walletRef, {
            ...walletData,
            schemaVersion: 1,
            migrationSource: "legacy_users",
            migratedAt: new Date(),
          });
        }
        if (!existingPublic.exists) {
          tx.create(publicRef, {
            ...publicData, schemaVersion: 1,
            updatedAt: new Date(),
          });
        }
        return {
          walletCreated: Number(!existingWallet.exists),
          walletAlreadyExists: Number(existingWallet.exists),
          publicProfileCreated: Number(!existingPublic.exists),
          publicProfileAlreadyExists: Number(existingPublic.exists),
        };
      });
      for (const [key, count] of Object.entries(outcome)) {
        stats[key] += count;
      }
    } catch (error) {
      if (error.message === "PRIVATE_WALLET_CONFLICT") {
        stats.conflicts += 1;
        throw new Error("Private wallet conflict: halted safely. " +
          "Reconcile changed balances from the trusted ledger before retry.");
      }
      throw error;
    }
  }
  if (page.size < 100 || stats.scanned >= maxUsers) break;
}
console.log(JSON.stringify({projectId, dryRun: !apply, ...stats}, null, 2));
if (!apply) {
  console.log("READ ONLY. No records changed. Run --apply only on a backed-up STAGING project.");
} else {
  console.log("Staging snapshots only. Legacy users financial fields are STILL exposed " +
    "to old clients until a separate verified backend/client/rules cutover.");
}
