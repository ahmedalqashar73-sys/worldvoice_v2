/**
 * One-time, non-destructive economy seed and legacy catalog preview.
 *
 * Usage: node scripts/seed-economy.mjs --project YOUR_FIREBASE_PROJECT
 *        node scripts/seed-economy.mjs --project YOUR_FIREBASE_PROJECT --apply
 *
 * --apply never overwrites existing records. Catalog item IDs use a type
 * prefix for safety. Prices and product identifiers MUST be approved before
 * an item can be activated. Do not run against production without a backup.
 */
import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

const args = process.argv.slice(2);
const projectIndex = args.indexOf("--project");
const projectId = projectIndex >= 0 ? args[projectIndex + 1] : "";
if (!projectId || !/^[a-z][a-z0-9-]+$/.test(projectId)) {
  throw new Error("Supply --project with a valid Firebase project ID.");
}
const apply = args.includes("--apply");
initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();

const policy = {
  enabled: false,
  walletPrivacyMigrationComplete: false,
  coinsPerUsd: null,
  receiverSharePercent: null,
  diamondUsdValue: null,
  withdrawalFeePercent: null,
  minWithdrawalDiamonds: null,
  holdDays: null,
  giftLevelPointsPerCoin: 1,
  exchangeBonusPercent: 10,
  webCardBonusPercent: 10,
  minExchangeDiamonds: 100,
  firstRechargeBonusPercent: null,
  purchaseDailyUsdLimit: null,
  giftingDailyCoinLimit: null,
  payoutWindows: [],
};

// PROPOSED pack sizes; user has NOT approved USD prices or product IDs.
// Inactive by design, with no redeemable checkout route.
const proposedSizes = [10, 50, 100, 500, 1000, 5000, 10000];
const batch = [];
batch.push([db.doc("economy_config/current"), policy]);
for (const coins of proposedSizes) {
  batch.push([db.doc(`coin_products/coins_${coins}`), {
    id: `coins_${coins}`,
    priceUsd: null,
    coins,
    androidProductId: null,
    iosProductId: null,
    webPriceId: null,
    active: false,
    priceApprovalRequired: true,
  }]);
}

for (const [sourceCollection, type] of [
  ["room_gift_catalog", "gift"],
  ["room_shop_items", "background"],
]) {
  const existing = await db.collection(sourceCollection).get();
  for (const snap of existing.docs) {
    const data = snap.data();
    const itemType = sourceCollection === "room_shop_items"
      ? String(data.type || "background")
      : type;
    if (!["gift", "background", "frame", "entrance", "vip"].includes(itemType)) {
      throw new Error(`Unexpected item type for ${sourceCollection}/${snap.id}`);
    }
    const priceCoins = Number(data.priceCoins);
    if (!Number.isSafeInteger(priceCoins) || priceCoins < 0) {
      throw new Error(`Invalid price in ${sourceCollection}/${snap.id}`);
    }
    batch.push([db.doc(`store_items/${itemType}__${snap.id}`), {
      type: itemType,
      legacyId: snap.id,
      sourceCollection,
      name: String(data.name || snap.id),
      priceCoins,
      requiredGiftLevel: data.requiredGiftLevel ?? null,
      durationDays: data.durationDays ?? null,
      animationUrl: data.animationUrl ?? null,
      previewUrl: data.previewUrl ?? null,
      themeId: data.themeId ?? null,
      active: false, // NEVER activate before backend/client migration.
      needsCatalogReview: true,
    }]);
  }
}
// Preserve already-purchased room backgrounds during catalog migration.
const oldBackgrounds = await db.collectionGroup("room_backgrounds").get();
for (const snap of oldBackgrounds.docs) {
  const userDoc = snap.ref.parent.parent;
  if (!userDoc || userDoc.parent.id !== "users") continue;
  const data = snap.data();
  const themeId = String(data.themeId || snap.id);
  batch.push([userDoc.collection("inventory").doc(`background__${themeId}`), {
    type: "background", themeId, itemId: `background__${themeId}`,
    quantity: 1, freeGiftBalance: 0, name: String(data.name || themeId),
    backgroundUrl: data.backgroundUrl || null,
    expiresAt: data.expiresAt || null, source: "legacy_background_import",
    importedFrom: snap.ref.path,
  }]);
}
console.log(JSON.stringify({
  projectId, dryRun: !apply, documents: batch.map(([ref]) => ref.path),
}, null, 2));
if (!apply) {
  console.log("Dry run only. Review the migration and rerun with --apply.");
  process.exit(0);
}
let created = 0;
for (const [ref, data] of batch) {
  // create() is conditional: safe to rerun and never overwrites a live price.
  try {
    await ref.create(data);
    created += 1;
  } catch (error) {
    if (Number(error?.code) === 6 || String(error?.code) === "already-exists") {
      console.log("Skipped existing:", ref.path);
      continue;
    }
    throw error;
  }
}
console.log(`Created ${created} new draft documents (all catalogs inactive).`);
