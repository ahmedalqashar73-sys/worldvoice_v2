/**
 * TWO-PHASE, DRY-RUN-FIRST profile-to-private-wallet migration.
 *
 * Only run after an external verified production Firestore backup and a
 * coordinated app/backend cutover. This script does not deploy rules, switch
 * services, change catalog active flags or launch monetary transactions.
 *
 * Preview:
 *   node scripts/migrate-private-wallets.mjs --project FIREBASE_PROJECT_ID
 * Apply to staging / explicitly approved backed-up project:
 *   node scripts/migrate-private-wallets.mjs --project FIREBASE_PROJECT_ID --apply --backup-confirmed
 */
import {applicationDefault, initializeApp} from "firebase-admin/app";
import {FieldPath, FieldValue, getFirestore} from "firebase-admin/firestore";
import {
  PRIVATE_WALLET_FIELDS, containsLegacyWalletFields,
  legacyWalletSnapshot, assertMigrationConsistency, privateWalletRef,
} from "../src/private_wallet_schema.js";

const argv=process.argv.slice(2);
function arg(name) {
  const index=argv.indexOf(name);
  return index >= 0 ? argv[index+1] : "";
}
const projectId=arg("--project");
const apply=argv.includes("--apply");
const backedUp=argv.includes("--backup-confirmed");
if (!projectId || !/^[a-z][a-z0-9-]{4,60}$/.test(projectId)) {
  throw new Error("A valid --project FIREBASE_PROJECT_ID is required.");
}
if (apply && !backedUp) {
  throw new Error("Refusing --apply without --backup-confirmed.");
}
initializeApp({credential:applicationDefault(), projectId});
const db=getFirestore();
let cursor=null;
let scanned=0, legacy=0, conflicts=0, migrated=0, alreadyPrivate=0;
while (true) {
  let query=db.collection("users")
    .orderBy(FieldPath.documentId()).limit(100);
  if (cursor) query=query.startAfter(cursor);
  const page=await query.get();
  if (page.empty) break;
  for (const doc of page.docs) {
    scanned++;
    const walletRef=privateWalletRef(doc.ref);
    const walletDoc=await walletRef.get();
    const profile=doc.data() || {};
    const oldWallet=containsLegacyWalletFields(profile);
    if (oldWallet) legacy++;
    if (walletDoc.exists) alreadyPrivate++;
    try {
      // Check consistency before deleting ANY data. A private wallet with
      // different values requires manual accounting reconciliation.
      const projection=legacyWalletSnapshot(profile);
      assertMigrationConsistency(walletDoc.data(), profile);
      if (!apply) continue;
      // Per-user atomic transaction avoids ever deleting a public balance
      // before its private destination is safely written.
      await db.runTransaction(async tx => {
        const [fresh, existing]=await Promise.all([
          tx.get(doc.ref),tx.get(walletRef),
        ]);
        const latest=fresh.data() || {};
        if (!fresh.exists) throw new Error("Profile changed during migration.");
        const values=legacyWalletSnapshot(latest);
        assertMigrationConsistency(existing.data(),latest);
        if (!existing.exists) {
          tx.create(walletRef,{
            ...values, schemaVersion:2,
            migratedAt:FieldValue.serverTimestamp(),
          });
        }
        if (containsLegacyWalletFields(latest)) {
          const removals=Object.fromEntries(
            PRIVATE_WALLET_FIELDS.filter(key =>
              Object.prototype.hasOwnProperty.call(latest,key))
              .map(key=>[key,FieldValue.delete()]),
          );
          tx.update(doc.ref,removals);
        }
      });
      migrated++;
    } catch(error) {
      conflicts++;
      // Redact monetary values and identifying profile metadata from logs.
      console.error("Migration conflict at user document; manual review required.",
        {userDocPath:doc.ref.path, reason:String(error.message)});
      if (apply) throw error;
    }
  }
  cursor=page.docs.at(-1).id;
  if (page.size < 100) break;
}
console.log(JSON.stringify({
  projectId, dryRun:!apply, scanned,
  profilesContainingLegacyWalletData:legacy,
  existingPrivateWallets:alreadyPrivate,
  migrated, conflicts,
  next:"Validate zero conflicts, document a verified backup and coordinate rules/client/backend upgrade.",
},null,2));
if (conflicts) process.exitCode=1;
