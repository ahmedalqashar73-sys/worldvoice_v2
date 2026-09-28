/**
 * STAGING-ONLY dry-run and conditional private wallet/profile projection.
 *
 * node scripts/stage-wallet-privacy.mjs --project worldvoice-staging
 * node scripts/stage-wallet-privacy.mjs --project worldvoice-staging \
 *   --apply --confirm-staging worldvoice-staging
 *
 * The script deliberately NEVER deletes the publicly readable legacy
 * users/{uid} money fields or enables economy_config. Full cutover requires
 * switching every client/backend consumer and publishing new profile rules.
 */
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {getFirestore, FieldPath, FieldValue} from "firebase-admin/firestore";
import {
  projectPrivateWallet, projectPublicProfile,
} from "../src/wallet_privacy_projection.js";

const args = process.argv.slice(2);
function value(flag) {
  const index = args.indexOf(flag);
  return index === -1 ? "" : args[index + 1] || "";
}
const projectId = value("--project");
const apply = args.includes("--apply");
if (!/^[a-z][a-z0-9-]{3,}$/.test(projectId)) {
  throw new Error("Supply an explicit valid --project for dry-run.");
}
if (apply && (!projectId.includes("staging") ||
    value("--confirm-staging") !== projectId)) {
  throw new Error("Writes are STAGING ONLY: require a staging project and --confirm-staging with the exact project ID.");
}
initializeApp({credential: applicationDefault(), projectId});
const db = getFirestore();

let scanned = 0;
let staged = 0;
let skipped = 0;
let conflicts = 0;
let previous = null;
while (true) {
  let query = db.collection("users").orderBy(FieldPath.documentId()).limit(200);
  if (previous) query = query.startAfter(previous);
  const batch = await query.get();
  if (batch.empty) break;
  for (const doc of batch.docs) {
    scanned++;
    const legacy = doc.data();
    const wallet = projectPrivateWallet(legacy, doc.id);
    const profile = projectPublicProfile(legacy, doc.id);
    const walletRef = doc.ref.collection("private").doc("wallet");
    const publicRef = db.collection("public_profiles").doc(doc.id);
    if (apply) {
      const outcome = await db.runTransaction(async tx => {
        const [existingWallet, existingPublic] = await Promise.all([
          tx.get(walletRef), tx.get(publicRef),
        ]);
        if (existingWallet.exists || existingPublic.exists) {
          // Never clobber newer wallet balances or selectively backfill one
          // document when a prior migration was only partially completed.
          return existingWallet.exists && existingPublic.exists
            ? "skipped" : "conflict";
        }
        tx.create(walletRef, {
          ...wallet, stagedAt: FieldValue.serverTimestamp(),
        });
        tx.create(publicRef, {
          ...profile, stagedAt: FieldValue.serverTimestamp(),
        });
        return "created";
      });
      if (outcome === "created") staged++;
      if (outcome === "skipped") skipped++;
      if (outcome === "conflict") conflicts++;
    } else {
      // Do not log private wallet amounts or personal profile data.
      staged++;
    }
  }
  previous = batch.docs.at(-1);
}
console.log(JSON.stringify({
  projectId, dryRun: !apply, scanned, staged,
  skipped, conflicts, legacyMoneyFieldsStillReadable: true,
  economyMayBeEnabled: false,
}, null, 2));
if (conflicts) process.exitCode = 2;
