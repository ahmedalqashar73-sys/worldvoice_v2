/**
 * Non-destructive preview-only seed of the agreed 30 classic gifts.
 *
 * node backend/scripts/seed-classic-gifts.mjs
 * FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node backend/scripts/seed-classic-gifts.mjs
 *   --project demo-worldvoice --apply --confirm-project demo-worldvoice
 *
 * No auto activation, no price changes to existing store documents, and
 * never applies to production: commercial rollout is a separate approval.
 */
import {readFileSync} from "node:fs";
import {fileURLToPath} from "node:url";
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";

const catalog = JSON.parse(readFileSync(
  fileURLToPath(new URL("../../assets/gifts/classic_premium_1_50.json",
    import.meta.url)), "utf8"));
if (catalog.catalogId !== "classic_1_50" ||
    !Array.isArray(catalog.gifts) || catalog.gifts.length !== 30 ||
    new Set(catalog.gifts.map(g => g.id)).size !== 30 ||
    catalog.gifts.some(g => !/^classic_[a-z0-9_]+$/.test(g.id) ||
      !Number.isSafeInteger(g.priceCoins) ||
      g.priceCoins < 1 || g.priceCoins > 50 ||
      !g.name || !g.nameAr || !g.emoji || !g.effectType)) {
  throw new Error("Invalid approved 30-gift preview catalog.");
}
const args = process.argv.slice(2);
function option(name) {
  const i = args.indexOf(name);
  return i === -1 ? null : args[i + 1];
}
const apply = args.includes("--apply");
const projectId = option("--project");
const confirm = option("--confirm-project");
const preview = catalog.gifts.map(g => ({
  document: `store_items/gift__${g.id}`,
  name: g.name, priceCoins: g.priceCoins,
  active: false, previewOnly: true,
}));
console.log(JSON.stringify({apply, count: preview.length, preview}, null, 2));
if (!apply) process.exit(0);

if (!projectId || !/^[a-z][a-z0-9-]+$/.test(projectId) ||
    confirm !== projectId ||
    (!process.env.FIRESTORE_EMULATOR_HOST &&
      !/(?:staging|test)(?:-|$)/.test(projectId))) {
  throw new Error(
    "Only an emulator/staging project can receive previews. " +
    "Supply --project and matching --confirm-project.");
}
initializeApp({
  credential: process.env.FIRESTORE_EMULATOR_HOST
    ? undefined : applicationDefault(),
  projectId,
});
const db = getFirestore();
const policy = await db.doc("economy_config/current").get();
if (policy.data()?.enabled !== false) {
  throw new Error("Staging economy must be explicitly disabled.");
}
let added = 0;
let existing = 0;
for (const g of catalog.gifts) {
  const doc = db.doc(`store_items/gift__${g.id}`);
  try {
    await doc.create({
      type: "gift", legacyId: g.id, category: catalog.catalogId,
      name: g.name, nameAr: g.nameAr,
      emoji: g.emoji, effectType: g.effectType,
      priceCoins: g.priceCoins, sortOrder: g.sortOrder,
      previewUrl: null, animationUrl: null,
      active: false, needsCatalogReview: true,
      presentationOnly: true,
    });
    added++;
  } catch (err) {
    if (Number(err.code) === 6 || String(err.code) === "already-exists") {
      // Never overwrite an existing product, price, or active flag.
      existing++;
      continue;
    }
    throw err;
  }
}
console.log(JSON.stringify({projectId, added, existing, allInactive: true}));
