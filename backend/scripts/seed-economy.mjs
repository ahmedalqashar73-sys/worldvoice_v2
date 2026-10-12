/**
 * One-time, non-destructive economy seed and legacy catalog preview.
 *
 * Usage: node scripts/seed-economy.mjs --project YOUR_FIREBASE_PROJECT
 *        node scripts/seed-economy.mjs --project YOUR_FIREBASE_PROJECT --apply
 *
 * --apply never overwrites existing records. Catalog item IDs use a type
 * prefix for safety. Coin packs remain draft-only. The WorldVoice cosmetic
 * items below are the approved built-in beta catalog and can be activated
 * without external image assets. Do not run against production without a backup.
 */
import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import {worldVoiceGiftCatalog, worldVoiceGiftStoreDocument} from "../src/gift_catalog.js";

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
  privateWalletCutoverVerified: false,
  publicProfileRulesVerified: false,
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

// User-approved WorldVoice coin tiers. SAR is the pricing reference agreed
// for launch planning; native stores still provide the actual localized price
// shown to buyers in each storefront. Products stay inactive until their real
// Google Play / App Store / Stripe IDs are configured and verified.
const proposedPacks = [
  {coins: 10, priceSar: 5, priceUsd: 1.33},
  {coins: 50, priceSar: 15, priceUsd: 4.00},
  {coins: 100, priceSar: 25, priceUsd: 6.67},
  {coins: 500, priceSar: 50, priceUsd: 13.33},
  {coins: 1000, priceSar: 85, priceUsd: 22.67},
  {coins: 2000, priceSar: 150, priceUsd: 40.00},
  {coins: 3000, priceSar: 200, priceUsd: 53.33},
  {coins: 5000, priceSar: 300, priceUsd: 80.00},
  {coins: 10000, priceSar: 500, priceUsd: 133.33},
];
const batch = [];
batch.push([db.doc("economy_config/current"), policy]);
for (const {coins, priceSar, priceUsd} of proposedPacks) {
  batch.push([db.doc(`coin_products/coins_${coins}`), {
    id: `coins_${coins}`,
    priceUsd,
    referencePriceSar: priceSar,
    coins,
    androidProductId: null,
    iosProductId: null,
    webPriceId: null,
    active: false,
    priceApprovalRequired: false,
  }]);
}

// Approved WorldVoice gift catalog. These 54 records are the only gift IDs
// the current Flutter client and /gift/send backend accept.
for (const giftId of worldVoiceGiftCatalog.keys()) {
  batch.push([
    db.doc(`store_items/gift__${giftId}`),
    worldVoiceGiftStoreDocument(giftId),
  ]);
}

const roomBackgrounds = [
  {id: "background__wv_premium_01", themeId: "wv_premium_01", name: "Enchanted Forest", nameAr: "الغابة الساحرة", priceCoins: 150},
  {id: "background__wv_premium_02", themeId: "wv_premium_02", name: "Crystal Sound", nameAr: "أمواج الصوت الكريستالية", priceCoins: 200},
  {id: "background__wv_premium_03", themeId: "wv_premium_03", name: "Starlight Circle", nameAr: "الدائرة النجمية", priceCoins: 250},
  {id: "background__wv_premium_04", themeId: "wv_premium_04", name: "Riverside Mill", nameAr: "طاحونة النهر", priceCoins: 180},
  {id: "background__wv_premium_05", themeId: "wv_premium_05", name: "Waterfall Cottage", nameAr: "كوخ الشلال", priceCoins: 220},
  {id: "background__wv_premium_06", themeId: "wv_premium_06", name: "Moonlit Falls", nameAr: "شلال ضوء القمر", priceCoins: 230},
  {id: "background__wv_premium_07", themeId: "wv_premium_07", name: "Dream Clouds", nameAr: "سحاب الأحلام", priceCoins: 120},
  {id: "background__wv_premium_08", themeId: "wv_premium_08", name: "WorldVoice Music", nameAr: "موسيقى وورلد فويس", priceCoins: 300},
];

for (const item of roomBackgrounds) {
  batch.push([db.doc(`store_items/${item.id}`), {
    type: "background",
    name: item.name,
    nameAr: item.nameAr,
    priceCoins: item.priceCoins,
    requiredGiftLevel: 0,
    durationDays: null,
    animationUrl: null,
    previewUrl: "",
    themeId: item.themeId,
    active: true,
    freeStarterGift: item.freeStarterGift === true,
    sourceCollection: "worldvoice_room_backgrounds_v2",
    builtInVisual: true,
  }]);
}

const premiumCosmetics = [
  {
    id: "frame__golden_crown",
    type: "frame",
    name: "Golden Crown",
    priceCoins: 220,
  },
  {
    id: "frame__royal_emerald",
    type: "frame",
    name: "Royal Emerald",
    priceCoins: 160,
  },
  {
    id: "frame__diamond_shine",
    type: "frame",
    name: "Diamond Shine",
    priceCoins: 300,
  },
  {
    id: "frame__neon_voice",
    type: "frame",
    name: "Neon Voice",
    priceCoins: 180,
  },
  {
    id: "frame__galaxy_ring",
    type: "frame",
    name: "Galaxy Ring",
    priceCoins: 260,
  },
];

for (const item of premiumCosmetics) {
  batch.push([db.doc(`store_items/${item.id}`), {
    type: item.type,
    name: item.name,
    priceCoins: item.priceCoins,
    requiredGiftLevel: 0,
    durationDays: null,
    animationUrl: null,
    previewUrl: "",
    themeId: item.themeId ?? null,
    active: true,
    sourceCollection: "worldvoice_builtin_cosmetics",
    builtInVisual: true,
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
// Hide every previous gift catalog entry from the store. Historical documents
// remain for ledger/audit safety, but they cannot be shown or sent again.
const approvedGiftStoreIds = new Set(
  [...worldVoiceGiftCatalog.keys()].map((giftId) => `gift__${giftId}`),
);
const currentGiftDocs = await db.collection("store_items")
  .where("type", "==", "gift").get();
for (const giftDoc of currentGiftDocs.docs) {
  if (!approvedGiftStoreIds.has(giftDoc.id)) {
    await giftDoc.ref.set({
      active: false,
      retiredFromCatalog: true,
      retiredBy: "worldvoice_gifts_v1",
    }, {merge: true});
  }
}

// Hide every previous background from the storefront, including old free
// gifts. Preserve records and historical entitlements for auditing.
const activeBackgroundIds = new Set(roomBackgrounds.map((item) => item.id));
const currentBackgroundDocs = await db.collection("store_items")
  .where("type", "==", "background").get();
for (const snap of currentBackgroundDocs.docs) {
  if (!activeBackgroundIds.has(snap.id)) {
    await snap.ref.set({
      active: false, retiredFromCatalog: true,
      retiredBy: "worldvoice_premium_backgrounds_v1",
    }, {merge: true});
  }
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
console.log(`Created ${created} new documents. Coin packs stay inactive; approved built-in cosmetics are active.`);