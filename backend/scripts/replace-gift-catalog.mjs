/**
 * Replace the Firestore gift store with the approved WorldVoice 54-gift pack.
 *
 * Dry run:
 *   node scripts/replace-gift-catalog.mjs --project YOUR_PROJECT
 * Apply:
 *   node scripts/replace-gift-catalog.mjs --project YOUR_PROJECT --apply
 *
 * Existing gift transaction history is never deleted. Old store_items of type
 * gift are only retired (active=false) so audit/history references remain valid.
 */
import {applicationDefault, initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {
  worldVoiceGiftCatalog,
  worldVoiceGiftStoreDocument,
} from "../src/gift_catalog.js";

const args = process.argv.slice(2);
const projectIndex = args.indexOf("--project");
const projectId = projectIndex >= 0 ? String(args[projectIndex + 1] || "") : "";
const apply = args.includes("--apply");

if (!/^[a-z][a-z0-9-]+$/.test(projectId)) {
  throw new Error("Supply --project with a valid Firebase project ID.");
}

initializeApp({credential: applicationDefault(), projectId});
const db = getFirestore();

const existing = await db.collection("store_items")
  .where("type", "==", "gift")
  .get();

const approvedIds = new Set(
  [...worldVoiceGiftCatalog.keys()].map((id) => `gift__${id}`),
);

const retire = existing.docs.filter((doc) => !approvedIds.has(doc.id));
const upserts = [...worldVoiceGiftCatalog.keys()].map((giftId) => ({
  ref: db.doc(`store_items/gift__${giftId}`),
  data: worldVoiceGiftStoreDocument(giftId),
}));

console.log(JSON.stringify({
  projectId,
  dryRun: !apply,
  retire: retire.map((doc) => doc.id),
  upsert: upserts.map(({ref, data}) => ({
    id: ref.id,
    priceCoins: data.priceCoins,
    tier: data.tier,
  })),
}, null, 2));

if (!apply) {
  console.log("Dry run only. Review, then rerun with --apply.");
  process.exit(0);
}

// Firestore batch limit is 500; this migration stays well below it.
const batch = db.batch();
for (const doc of retire) {
  batch.set(doc.ref, {
    active: false,
    retiredFromCatalog: true,
    retiredAt: FieldValue.serverTimestamp(),
  }, {merge: true});
}
for (const {ref, data} of upserts) {
  batch.set(ref, {
    ...data,
    retiredFromCatalog: false,
    catalogUpdatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
}
await batch.commit();

console.log(
  `Gift catalog replaced: ${retire.length} retired, ${upserts.length} approved.`,
);
