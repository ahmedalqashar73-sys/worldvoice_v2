/**
 * Stage 1 of the private-wallet migration (NON-DESTRUCTIVE).
 *
 * Preview:
 *   node scripts/migrate-private-wallets.mjs --project YOUR_STAGING_PROJECT
 * Write only after an independent backup and review:
 *   node scripts/migrate-private-wallets.mjs --project YOUR_STAGING_PROJECT \\
 *       --apply --backup-confirmed
 *
 * Uses current user snapshots in each Firestore transaction; existing wallet
 * and public-profile records are NEVER overwritten. Original user fields are
 * NEVER removed here: that requires coordinated client/backend/rules cutover.
 * Run against isolated staging, audit all mismatches, then review rollout.
 */
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {getFirestore, FieldPath, FieldValue} from "firebase-admin/firestore";
import {
  projectPrivateWallet, projectPublicProfile,
} from "../src/private_wallet_projection.js";

const flags = process.argv.slice(2);
const index = flags.indexOf("--project");
const projectId = index < 0 ? "" : String(flags[index + 1] || "");
const apply = flags.includes("--apply");
const confirmed = flags.includes("--backup-confirmed");
const limitAt = flags.indexOf("--limit");
const limit = limitAt < 0 ? 0 : Number(flags[limitAt + 1]);
if (!/^[a-z][a-z0-9-]{3,62}$/.test(projectId)) {
  throw new Error("Provide a valid --project Firebase staging project ID.");
}
if (apply && !confirmed) {
  throw new Error("--apply requires --backup-confirmed and a verified backup.");
}
if (limitAt >= 0 && (!Number.isSafeInteger(limit) || limit < 1)) {
  throw new Error("--limit must be a positive integer.");
}
initializeApp({credential: applicationDefault(), projectId});
const db = getFirestore();
let seen = 0;
let createdWallets = 0;
let createdProfiles = 0;
let existingWallets = 0;
let existingProfiles = 0;
let cursor;

while (true) {
  let query = db.collection("users")
      .orderBy(FieldPath.documentId()).limit(100);
  if (cursor) query = query.startAfter(cursor);
  const page = await query.get();
  if (page.empty) break;

  for (const snap of page.docs) {
    // Do not silently include more people than the reviewed preview count.
    if (limit && seen >= limit) break;
    const walletRef = snap.ref.collection("private").doc("wallet");
    const profileRef = db.collection("public_profiles").doc(snap.id);
    let outcome;
    if (!apply) {
      const [walletSnap, profileSnap] = await Promise.all([
        walletRef.get(), profileRef.get(),
      ]);
      // Validate BEFORE publishing any projection for this account.
      const wallet = projectPrivateWallet(snap.data());
      const profile = projectPublicProfile(snap.id, snap.data());
      outcome = {
        walletExists: walletSnap.exists,
        profileExists: profileSnap.exists,
        walletFields: Object.keys(wallet),
        publicFields: Object.keys(profile),
      };
    } else {
      outcome = await db.runTransaction(async tx => {
        const [userSnap, walletSnap, profileSnap] = await Promise.all([
          tx.get(snap.ref),
          tx.get(walletRef),
          tx.get(profileRef),
        ]);
        if (!userSnap.exists) {
          throw new Error(`User disappeared during migration: ${snap.id}`);
        }
        const wallet = projectPrivateWallet(userSnap.data());
        const profile = projectPublicProfile(snap.id, userSnap.data());
        if (!walletSnap.exists) {
          tx.create(walletRef, {
            ...wallet,
            schemaVersion: 1,
            migratedAt: FieldValue.serverTimestamp(),
          });
        }
        if (!profileSnap.exists) {
          tx.create(profileRef, {
            ...profile,
            schemaVersion: 1,
            projectedAt: FieldValue.serverTimestamp(),
          });
        }
        return {
          walletExists: walletSnap.exists,
          profileExists: profileSnap.exists,
          walletFields: Object.keys(wallet),
          publicFields: Object.keys(profile),
        };
      });
    }
    seen++;
    if (outcome.walletExists) existingWallets++; else createdWallets++;
    if (outcome.profileExists) existingProfiles++; else createdProfiles++;
    // Avoid printing balances, personal information or names into CI logs.
    console.log(JSON.stringify({
      userOrdinal: seen,
      walletAction: outcome.walletExists ? "existing" : apply ? "created" : "would_create",
      profileAction: outcome.profileExists ? "existing" : apply ? "created" : "would_create",
      privateFieldNames: outcome.walletFields,
      publicFieldNames: outcome.publicFields,
    }));
  }
  if ((limit && seen >= limit) || page.size < 100) break;
  cursor = page.docs[page.docs.length - 1];
}

console.log(JSON.stringify({
  projectId,
  dryRun: !apply,
  seen,
  walletsToCreateOrCreated: createdWallets,
  profilesToCreateOrCreated: createdProfiles,
  existingWallets,
  existingProfiles,
  // IMPORTANT: legacy users documents have not been redacted yet.
  publicFinanceStillExposedUntilVerifiedCutover: true,
}, null, 2));
