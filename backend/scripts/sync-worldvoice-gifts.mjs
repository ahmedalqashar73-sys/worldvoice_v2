import { applicationDefault, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

import {
  worldVoiceGiftCatalog,
  worldVoiceGiftStoreDocument,
} from "../src/gift_catalog.js";

const args = process.argv.slice(2);
const projectIndex = args.indexOf("--project");
const projectId = projectIndex >= 0 ? args[projectIndex + 1] : "";
const apply = args.includes("--apply");

if (!projectId || !/^[a-z][a-z0-9-]+$/.test(projectId)) {
  throw new Error("Supply --project with a valid Firebase project ID.");
}

initializeApp({credential: applicationDefault(), projectId});
const db = getFirestore();

const approvedIds = new Set(
  [...worldVoiceGiftCatalog.keys()].map((giftId) => `gift__${giftId}`),
);

const existing = await db.collection("store_items")
  .where("type", "==", "gift")
  .get();

const retire = existing.docs
  .filter((doc) => !approvedIds.has(doc.id))
  .map((doc) => doc.id)
  .sort();

const upsert = [...worldVoiceGiftCatalog.keys()].map((giftId) => ({
  id: `gift__${giftId}`,
  data: worldVoiceGiftStoreDocument(giftId),
}));

console.log(JSON.stringify({
  projectId,
  dryRun: !apply,
  approvedCount: upsert.length,
  retireCount: retire.length,
  retire,
}, null, 2));

if (!apply) {
  console.log("Dry run only. Review then rerun with --apply.");
  process.exit(0);
}

const batch = db.batch();

for (const id of retire) {
  batch.set(db.doc(`store_items/${id}`), {
    active: false,
    retiredFromCatalog: true,
    retiredBy: "worldvoice_gifts_v1",
  }, {merge: true});
}

for (const item of upsert) {
  batch.set(db.doc(`store_items/${item.id}`), {
    ...item.data,
    retiredFromCatalog: false,
    needsCatalogReview: false,
  }, {merge: true});
}

await batch.commit();

console.log(
  `WorldVoice gift store synced: ${upsert.length} approved, ${retire.length} retired.`,
);
