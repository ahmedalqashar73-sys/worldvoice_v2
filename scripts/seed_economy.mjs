// Run from repository root:
//   node scripts/seed_economy.mjs --input economy.private.json         (dry-run)
//   node scripts/seed_economy.mjs --input economy.private.json --apply (write disabled catalog)
// All coin prices and exchange rates come from the private supplied JSON;
// never place private provider tokens in the seed file.
import fs from "node:fs/promises";
import { applicationDefault, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { validateEconomy } from "../backend/src/economy_core.js";

const args = process.argv;
const arg = (flag) => args.includes(flag) ? args[args.indexOf(flag) + 1] : null;
const input = arg("--input");
if (!input) throw new Error("Provide --input path to a reviewed economy JSON file.");
const payload = JSON.parse(await fs.readFile(input, "utf8"));
const config = payload.economy_config;
const catalog = payload.coin_products;
if (!config || !Array.isArray(catalog) || catalog.length !== 7)
  throw new Error("Exactly seven coin_products and economy_config are required.");
// Validate every required rate, even when the feature remains disabled.
validateEconomy({ ...config, enabled:true });
const ids = new Set(), androidIds = new Set(), iosIds = new Set();
for (const pack of catalog) {
  if (typeof pack.id !== "string" || !/^[a-z0-9_-]+$/.test(pack.id) ||
      typeof pack.priceUsd !== "number" || pack.priceUsd <= 0 ||
      !Number.isSafeInteger(pack.coins) || pack.coins <= 0 ||
      !["androidProductId", "iosProductId", "webPriceId"].every(
        (key) => typeof pack[key] === "string" && pack[key].length > 0) ||
      typeof pack.active !== "boolean")
    throw new Error("Incomplete coin product: " + JSON.stringify(pack));
  if (ids.has(pack.id) || androidIds.has(pack.androidProductId) ||
      iosIds.has(pack.iosProductId))
    throw new Error("Product IDs must be unique across the seven packages.");
  ids.add(pack.id); androidIds.add(pack.androidProductId);
  iosIds.add(pack.iosProductId);
}
if (!args.includes("--apply")) {
  console.log("DRY RUN OK: Seven products and central economy config validated.");
  console.log("Use --apply only after reviewing every USD price, app store product ID, and policy.");
  process.exit(0);
}
const projectId = process.env.FIREBASE_PROJECT_ID;
if (!projectId) throw new Error("Set FIREBASE_PROJECT_ID explicitly before writing.");
initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();
const batch = db.batch();
// Never automatically enable finance while payments, audit, and KYC are
// being connected. Activation requires a separate reviewed admin action.
batch.set(db.collection("economy_config").doc("global"), {
  ...config, enabled:false,
  updatedAt:new Date(),
}, { merge:true });
for (const pack of catalog) {
  batch.set(db.collection("coin_products").doc(pack.id), { ...pack,
    active:false,
  }, { merge:true });
}
await batch.commit();
console.log("Seeded disabled economy_config and seven disabled products to", projectId);
if (args.includes("--migrate-legacy")) {
  const gifts = await db.collection("room_gift_catalog").get();
  const shop = await db.collection("room_shop_items").get();
  const merged = new Map();
  for (const doc of gifts.docs) merged.set(doc.id, {
    ...doc.data(), type:"gift", requiredGiftLevel: doc.data().requiredGiftLevel ?? 0,
    durationDays:null,
  });
  for (const doc of shop.docs) {
    if (merged.has(doc.id)) throw new Error(
      "Legacy gift and shop share ID: " + doc.id + " - review manually.");
    merged.set(doc.id, {
      ...doc.data(), type:doc.data().type || "background",
      requiredGiftLevel:doc.data().requiredGiftLevel ?? 0,
      durationDays:doc.data().durationDays ?? null,
    });
  }
  // Deliberately inactive until admin inspects EVERY gift price.
  for (const [itemId, item] of merged) {
    const ref = db.collection("store_items").doc(itemId);
    if ((await ref.get()).exists)
      throw new Error("store_items/" + itemId + " exists. Merge manually.");
    await ref.create({ ...item, active:false, legacyId:itemId,
      migratedAt:new Date() });
  }
  console.log("Migrated", merged.size, "legacy items as INACTIVE. Review before activation.");
}
