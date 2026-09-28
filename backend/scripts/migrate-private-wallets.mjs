/**
 * Staged privacy migration. No writes by default.
 *
 * Preview: node scripts/migrate-private-wallets.mjs --project PROJECT_ID
 * Apply AFTER an externally verified Firestore backup, with deployed finance
 * routes stopped and economy_config/current.enabled=false:
 *   ECONOMY_MIGRATION_APPROVED=YES ECONOMY_WRITES_PAUSED=YES \
 *   node scripts/migrate-private-wallets.mjs --project PROJECT_ID \
 *     --backup-verified --apply
 *
 * Each user's private wallet creation, sanitized public profile projection
 * and removal of legacy balance fields share one Firestore transaction.
 * Never reconstruct an already-migrated wallet from stale profile values.
 */
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {
  walletFields, walletRef, projectWallet, projectPublicProfile,
} from "../src/wallet_schema.js";

const args = process.argv.slice(2);
const flag = value => args.includes(value);
const projectIndex = args.indexOf("--project");
const projectId = projectIndex < 0 ? "" : args[projectIndex + 1];
if (!/^[a-z][a-z0-9-]+$/.test(projectId || "")) {
  throw new Error("Supply a valid --project PROJECT_ID.");
}
const apply = flag("--apply");
if (apply && (!flag("--backup-verified") ||
    process.env.ECONOMY_MIGRATION_APPROVED !== "YES" ||
    process.env.ECONOMY_WRITES_PAUSED !== "YES")) {
  throw new Error("Apply requires backup proof and both migration safety gates.");
}
initializeApp({credential: applicationDefault(), projectId});
const db = getFirestore();
if (apply) {
  const config = await db.doc("economy_config/current").get();
  if (config.data()?.enabled === true) {
    throw new Error("Disable live economy BEFORE private-wallet migration.");
  }
}
const stats = {scanned: 0, toMigrate: 0, migrated: 0, alreadyMigrated: 0,
  conflicts: 0, projectedOnly: 0};
const profiles = await db.collection("users").get();
for (const profile of profiles.docs) {
  const uid = profile.id;
  const data = profile.data() || {};
  const wallet = walletRef(db, uid);
  const publicDoc = db.collection("public_profiles").doc(uid);
  const oldBalanceFields = walletFields.filter(k => Object.hasOwn(data, k));
  const priorWallet = await wallet.get();
  stats.scanned++;
  if (priorWallet.exists && oldBalanceFields.length) {
    // A rerun is safe only if the legacy data genuinely matches the wallet.
    // A financially active wallet cannot be overwritten or reconstructed.
    stats.conflicts++;
    console.log(JSON.stringify({uid, status: "manual_wallet_reconciliation_required"}));
    continue;
  }
  if (priorWallet.exists) stats.alreadyMigrated++;
  else stats.toMigrate++;
  if (!apply) {
    // Validate all legacy financial fields BEFORE reporting an apply candidate.
    if (!priorWallet.exists) projectWallet(data);
    continue;
  }
  const result = await db.runTransaction(async tx => {
    const [current, existingWallet, existingPublic] = await Promise.all([
      tx.get(profile.ref), tx.get(wallet), tx.get(publicDoc),
    ]);
    if (!current.exists) return "no_profile";
    const currentData = current.data() || {};
    const liveLegacy = walletFields.filter(k => Object.hasOwn(currentData, k));
    if (existingWallet.exists && liveLegacy.length) return "conflict";
    // A new public view is created only from the current private profile.
    if (!existingPublic.exists) {
      tx.create(publicDoc, projectPublicProfile({...currentData, uid}));
    }
    if (existingWallet.exists) return existingPublic.exists
      ? "already_migrated" : "projected_only";
    tx.create(wallet, {...projectWallet(currentData),
      createdAt: FieldValue.serverTimestamp(),
      migratedAt: FieldValue.serverTimestamp()});
    if (liveLegacy.length) {
      tx.update(profile.ref, Object.fromEntries(
        liveLegacy.map(name => [name, FieldValue.delete()])));
    }
    return "migrated";
  });
  if (result === "migrated") stats.migrated++;
  if (result === "projected_only") stats.projectedOnly++;
  if (result === "conflict") {
    stats.conflicts++;
    console.log(JSON.stringify({uid, status: "concurrent_write_conflict"}));
  }
}
console.log(JSON.stringify({projectId, apply, ...stats}, null, 2));
if (stats.conflicts) {
  process.exitCode = 2;
  console.error("Manual conflicts present: DO NOT enable economy or tighten rules.");
}
