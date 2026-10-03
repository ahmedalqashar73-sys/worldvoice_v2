/**
 * STAGING ONLY: create owner-only users/{uid}/private/wallet snapshots and
 * allowlisted public_profiles/{uid} projections without touching legacy data.
 *
 * Examples:
 *   node scripts/stage-private-wallet.mjs --project demo-worldvoice
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node scripts/stage-private-wallet.mjs \
 *     --project demo-worldvoice --apply --confirm-project demo-worldvoice
 *
 * Neither preview nor apply removes public legacy finance fields. Rollout
 * requires migrating EVERY backend writer and client reader and then changing
 * public users/{uid} rules with a complete old-client compatibility plan.
 */
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {getFirestore, FieldPath, FieldValue} from "firebase-admin/firestore";
import {
  projectPublicProfile, extractLegacyWallet,
  assertExistingProjectionMatches,
} from "../src/profile_projection.js";

const args = process.argv.slice(2);
function flag(name) {
  const idx = args.indexOf(name);
  return idx >= 0 ? args[idx + 1] : null;
}
const projectId = flag("--project");
const apply = args.includes("--apply");
const confirmation = flag("--confirm-project");
const maxUsers = Number(flag("--max-users") || 250);

if (!projectId || !/^[a-z][a-z0-9-]+$/.test(projectId) ||
    !Number.isSafeInteger(maxUsers) || maxUsers <= 0 || maxUsers > 2000) {
  throw new Error("Specify valid --project and optional --max-users 1..2000.");
}
if (apply && (confirmation !== projectId ||
    (!process.env.FIRESTORE_EMULATOR_HOST &&
     !/(?:staging|test)(?:-|$)/.test(projectId)))) {
  throw new Error("Applying requires matching --confirm-project and an emulator or staging/test project.");
}

initializeApp({
  credential: process.env.FIRESTORE_EMULATOR_HOST ? undefined : applicationDefault(),
  projectId,
});
const db = getFirestore();
if (apply) {
  const cfg = await db.doc("economy_config/current").get();
  if (cfg.data()?.enabled !== false) {
    throw new Error("Disable economy_config/current before staging.");
  }
}

let visited = 0;
let staged = 0;
let existing = 0;
let last = null;
while (visited < maxUsers) {
  let query = db.collection("users")
    .orderBy(FieldPath.documentId())
    .limit(Math.min(100, maxUsers - visited));
  if (last) query = query.startAfter(last);
  const page = await query.get();
  if (page.empty) break;
  for (const doc of page.docs) {
    visited++;
    const legacy = doc.data();
    const publicProfile = projectPublicProfile(doc.id, legacy);
    const privateWallet = extractLegacyWallet(legacy);
    // No sensitive values, names or wallet balances in migration logs.
    if (!apply) {
      console.log(JSON.stringify({userDocument: visited,
        publicFields: Object.keys(publicProfile).length,
        walletFields: Object.keys(privateWallet).length,
        mode: "PREVIEW_ONLY"}));
      continue;
    }
    const walletRef = doc.ref.collection("private").doc("wallet");
    const publicRef = db.collection("public_profiles").doc(doc.id);
    const result = await db.runTransaction(async tx => {
      const [currentSource, walletSnap, publicSnap] = await Promise.all([
        tx.get(doc.ref), tx.get(walletRef), tx.get(publicRef),
      ]);
      // Re-read within the transaction: a concurrently edited legacy
      // profile must never produce a stale private-wallet snapshot.
      if (!currentSource.exists ||
          currentSource.updateTime?.toMillis() !== doc.updateTime?.toMillis()) {
        throw new Error("Source changed while staging; restart the audit.");
      }
      const currentWallet = extractLegacyWallet(currentSource.data());
      const currentPublic = projectPublicProfile(doc.id, currentSource.data());
      if (walletSnap.exists) {
        assertExistingProjectionMatches(
          currentWallet, walletSnap.data(), "private wallet");
      } else {
        tx.create(walletRef, {
          ...currentWallet, migrationSource: "legacy_users",
          stagedAt: FieldValue.serverTimestamp(),
        });
      }
      if (publicSnap.exists) {
        assertExistingProjectionMatches(
          currentPublic, publicSnap.data(), "public profile");
      } else {
        tx.create(publicRef, {
          ...currentPublic, migrationSource: "legacy_users",
          stagedAt: FieldValue.serverTimestamp(),
        });
      }
      return walletSnap.exists && publicSnap.exists ? "existing" : "staged";
    });
    if (result === "staged") staged++;
    else existing++;
  }
  last = page.docs.at(-1);
  if (page.size < Math.min(100, maxUsers - visited + page.size)) break;
}
console.log(JSON.stringify({
  projectId, apply, visited, staged, existing,
  safeForProduction: false,
  note: "Legacy public financial fields remain unchanged; do not deploy public profile rules yet.",
}));
