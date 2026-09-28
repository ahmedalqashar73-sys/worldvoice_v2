/**
 * Staged, NON-DESTRUCTIVE privacy migration.
 * Dry run: node scripts/prepare-private-wallets.mjs --project YOUR_PROJECT
 * Apply AFTER BACKUP:
 *   node scripts/prepare-private-wallets.mjs --project YOUR_PROJECT --apply --backup-confirmed
 *
 * This does NOT remove legacy public financial fields. Keep economy disabled
 * until ALL readers/writers have moved and a frozen final reconciliation
 * is complete. Avoid treating a migration snapshot as a live balance.
 */
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {FieldPath, FieldValue, getFirestore} from "firebase-admin/firestore";
import {
  sanitizedPublicProfile, extractPrivateWallet,
  walletCopyMatches, publicCopyMatches,
} from "../src/wallet_privacy.js";

const args = process.argv.slice(2);
const projectAt = args.indexOf("--project");
const projectId = projectAt < 0 ? "" : String(args[projectAt + 1] || "");
if (!/^[a-z][a-z0-9-]+$/.test(projectId)) {
  throw new Error("Provide --project with your Firebase project ID.");
}
const apply = args.includes("--apply");
if (apply && !args.includes("--backup-confirmed")) {
  throw new Error("Do not apply without a Firestore backup; pass --backup-confirmed.");
}
initializeApp({credential: applicationDefault(), projectId});
const db = getFirestore();
const stats = {scanned: 0, walletsMissing: 0, profilesMissing: 0,
  migrated: 0, existing: 0, conflicts: 0, invalidLegacy: 0};
let after = null;
do {
  let query = db.collection("users").orderBy(FieldPath.documentId()).limit(200);
  if (after) query = query.startAfter(after);
  const page = await query.get();
  if (page.empty) break;
  for (const doc of page.docs) {
    stats.scanned++;
    // Re-read the source IN the transaction: do not migrate stale money.
    const privateRef = doc.ref.collection("private").doc("wallet");
    const publicRef = db.collection("public_profiles").doc(doc.id);
    if (!apply) {
      try {extractPrivateWallet(doc.data());} catch {
        stats.invalidLegacy++;
        continue;
      }
      const [wallet, profile] = await Promise.all([
        privateRef.get(), publicRef.get(),
      ]);
      if (!wallet.exists) stats.walletsMissing++;
      else if (!walletCopyMatches(doc.data(), wallet.data())) stats.conflicts++;
      if (!profile.exists) stats.profilesMissing++;
      else if (!publicCopyMatches(doc.id, doc.data(), profile.data())) {
        stats.conflicts++;
      }
      continue;
    }
    try {
      const result = await db.runTransaction(async tx => {
        const [latest, privateDoc, publicDoc] = await Promise.all([
          tx.get(doc.ref), tx.get(privateRef), tx.get(publicRef),
        ]);
        if (!latest.exists) return "existing";
        const financial = extractPrivateWallet(latest.data());
        const profile = sanitizedPublicProfile(doc.id, latest.data());
        // Reject stale copies instead of silently treating them as current.
        // A partial previous migration may safely create only the missing
        // document, never overwrite a newer wallet or published profile.
        if (privateDoc.exists &&
            !walletCopyMatches(latest.data(), privateDoc.data())) {
          return "conflicts";
        }
        if (publicDoc.exists &&
            !publicCopyMatches(doc.id, latest.data(), publicDoc.data())) {
          return "conflicts";
        }
        if (privateDoc.exists && publicDoc.exists) return "existing";
        if (!privateDoc.exists) {
          tx.create(privateRef, {
            ...financial,
            migrationVersion: 1,
            snapshotAt: FieldValue.serverTimestamp(),
            legacySource: "users/" + doc.id,
          });
        }
        if (!publicDoc.exists) {
          tx.create(publicRef, {
            ...profile, migrationVersion: 1,
            snapshotAt: FieldValue.serverTimestamp(),
          });
        }
        return "migrated";
      });
      stats[result] = (stats[result] || 0) + 1;
    } catch (error) {
      if (/Invalid legacy/.test(String(error))) stats.invalidLegacy++;
      else stats.conflicts++;
    }
  }
  after = page.docs.at(-1);
  if (page.size < 200) break;
} while (true);
console.log(JSON.stringify({projectId, dryRun: !apply, ...stats}, null, 2));
if (stats.conflicts || stats.invalidLegacy) {
  process.exitCode = 1; // Halt migration rather than hiding bad balances.
}
