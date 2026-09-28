/**
 * Read-only account-by-account financial privacy cutover audit.
 *
 * Run only AFTER legacy money/profile writes have been frozen and a backup
 * has been captured; concurrent writes produce mismatches.
 *
 *   node scripts/audit-private-wallets.mjs --project YOUR_STAGING_PROJECT
 *
 * Never logs UIDs, balances, payout details or profile data.
 * NEVER treats this audit alone as permission to enable payments:
 * existing /users/{uid} must also stop exposing legacy financial fields,
 * all clients/backend must switch to private wallets, and rules must be
 * tested with separate user identities before production deployment.
 */
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {FieldPath, getFirestore} from "firebase-admin/firestore";
import {auditPrivacySnapshot} from "../src/wallet_privacy.js";

const args = process.argv.slice(2);
const at = args.indexOf("--project");
const project = at >= 0 ? String(args[at + 1] || "") : "";
if (!/^[a-z][a-z0-9-]+$/.test(project)) {
  throw new Error("Supply --project YOUR_STAGING_PROJECT.");
}
if (args.includes("--apply")) {
  throw new Error("This audit is read-only; --apply is not supported.");
}

initializeApp({credential: applicationDefault(), projectId: project});
const db = getFirestore();
const summary = {scanned: 0, clean: 0, issueCounts: {}};
let cursor = null;
do {
  let q = db.collection("users").orderBy(FieldPath.documentId()).limit(100);
  if (cursor) q = q.startAfter(cursor);
  const batch = await q.get();
  if (batch.empty) break;

  for (const legacyDoc of batch.docs) {
    summary.scanned++;
    const [privateDoc, publicDoc] = await Promise.all([
      legacyDoc.ref.collection("private").doc("wallet").get(),
      db.collection("public_profiles").doc(legacyDoc.id).get(),
    ]);
    const issues = auditPrivacySnapshot(
      legacyDoc.id, legacyDoc.data(),
      privateDoc.exists ? privateDoc.data() : null,
      publicDoc.exists ? publicDoc.data() : null,
    );
    if (!issues.length) summary.clean++;
    for (const issue of issues) {
      summary.issueCounts[issue] = (summary.issueCounts[issue] || 0) + 1;
    }
  }
  cursor = batch.docs.at(-1);
  if (batch.size < 100) break;
} while (true);

console.log(JSON.stringify({
  project, readOnly: true, requiresFrozenLegacyWrites: true, ...summary,
}, null, 2));
if (summary.clean !== summary.scanned) process.exitCode = 1;
