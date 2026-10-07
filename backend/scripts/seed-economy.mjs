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

const roomBackgrounds = [
  {id: "background__wv_bg_06", themeId: "wv_bg_06", name: "Golden Coast", nameAr: "الساحل الذهبي", priceCoins: 0, freeStarterGift: true},
  {id: "background__wv_bg_09", themeId: "wv_bg_09", name: "Garden Escape", nameAr: "ملاذ الحديقة", priceCoins: 0, freeStarterGift: true},
  {id: "background__wv_bg_18", themeId: "wv_bg_18", name: "Sunset Terrace", nameAr: "شرفة الغروب", priceCoins: 0, freeStarterGift: true},
  {id: "background__wv_bg_20", themeId: "wv_bg_20", name: "Alpine Serenity", nameAr: "هدوء الألب", priceCoins: 0, freeStarterGift: true},
  {id: "background__wv_bg_33", themeId: "wv_bg_33", name: "Crystal Lagoon", nameAr: "البحيرة الكريستالية", priceCoins: 0, freeStarterGift: true},
  {id: "background__wv_bg_01", themeId: "wv_bg_01", name: "Aurora Wolf", nameAr: "ذئب الشفق القطبي", priceCoins: 260},
  {id: "background__wv_bg_02", themeId: "wv_bg_02", name: "Moonlit Castle", nameAr: "قلعة ضوء القمر", priceCoins: 320},
  {id: "background__wv_bg_03", themeId: "wv_bg_03", name: "Celestial Falls", nameAr: "شلالات الفردوس", priceCoins: 280},
  {id: "background__wv_bg_04", themeId: "wv_bg_04", name: "Sapphire Palace", nameAr: "قصر الياقوت", priceCoins: 350},
  {id: "background__wv_bg_05", themeId: "wv_bg_05", name: "Golden Royal Hall", nameAr: "القاعة الملكية الذهبية", priceCoins: 380},
  {id: "background__wv_bg_07", themeId: "wv_bg_07", name: "Midnight Venice", nameAr: "فينيسيا منتصف الليل", priceCoins: 160},
  {id: "background__wv_bg_08", themeId: "wv_bg_08", name: "Neon Royal Drive", nameAr: "جولة النيون الملكية", priceCoins: 260},
  {id: "background__wv_bg_10", themeId: "wv_bg_10", name: "Frozen Crystal Palace", nameAr: "قصر الكريستال المتجمد", priceCoins: 360},
  {id: "background__wv_bg_11", themeId: "wv_bg_11", name: "Panda Paradise", nameAr: "جنة الباندا", priceCoins: 220},
  {id: "background__wv_bg_12", themeId: "wv_bg_12", name: "Desert Oasis", nameAr: "واحة الغروب", priceCoins: 180},
  {id: "background__wv_bg_13", themeId: "wv_bg_13", name: "Misty Dynasty", nameAr: "مملكة الضباب", priceCoins: 200},
  {id: "background__wv_bg_14", themeId: "wv_bg_14", name: "Violet Moon Kingdom", nameAr: "مملكة القمر البنفسجي", priceCoins: 300},
  {id: "background__wv_bg_15", themeId: "wv_bg_15", name: "Sakura Imperial", nameAr: "ساكورا الإمبراطورية", priceCoins: 280},
  {id: "background__wv_bg_16", themeId: "wv_bg_16", name: "Royal Peacock Garden", nameAr: "حديقة الطاووس الملكية", priceCoins: 320},
  {id: "background__wv_bg_17", themeId: "wv_bg_17", name: "Rose Cat Palace", nameAr: "قصر القطة والورود", priceCoins: 240},
  {id: "background__wv_bg_19", themeId: "wv_bg_19", name: "Pharaoh Sunset", nameAr: "غروب الفراعنة", priceCoins: 300},
  {id: "background__wv_bg_21", themeId: "wv_bg_21", name: "Tropical Royal Lounge", nameAr: "الواحة الملكية الاستوائية", priceCoins: 240},
  {id: "background__wv_bg_22", themeId: "wv_bg_22", name: "Emerald Cave", nameAr: "كهف الزمرد", priceCoins: 320},
  {id: "background__wv_bg_23", themeId: "wv_bg_23", name: "Parisian Twilight", nameAr: "شفق باريس", priceCoins: 220},
  {id: "background__wv_bg_24", themeId: "wv_bg_24", name: "Starlight Palace", nameAr: "قصر ضوء النجوم", priceCoins: 380},
  {id: "background__wv_bg_25", themeId: "wv_bg_25", name: "Alpine Royal Retreat", nameAr: "منتجع الألب الملكي", priceCoins: 220},
  {id: "background__wv_bg_26", themeId: "wv_bg_26", name: "Panther Moon", nameAr: "فهد القمر", priceCoins: 420},
  {id: "background__wv_bg_27", themeId: "wv_bg_27", name: "Atlantis Luxury Suite", nameAr: "جناح أتلانتس الفاخر", priceCoins: 450},
  {id: "background__wv_bg_28", themeId: "wv_bg_28", name: "Stadium Glory", nameAr: "مجد الملعب", priceCoins: 300},
  {id: "background__wv_bg_29", themeId: "wv_bg_29", name: "Number 10 Legend", nameAr: "أسطورة الرقم 10", priceCoins: 340},
  {id: "background__wv_bg_30", themeId: "wv_bg_30", name: "Panda Falls", nameAr: "شلالات الباندا", priceCoins: 280},
  {id: "background__wv_bg_31", themeId: "wv_bg_31", name: "Royal Lion Sunset", nameAr: "أسد الغروب الملكي", priceCoins: 450},
  {id: "background__wv_bg_32", themeId: "wv_bg_32", name: "Tiger Falls", nameAr: "شلالات النمر", priceCoins: 480},
  {id: "background__wv_bg_34", themeId: "wv_bg_34", name: "Mountain Mirror Retreat", nameAr: "ملاذ مرآة الجبل", priceCoins: 240},
  {id: "background__wv_bg_35", themeId: "wv_bg_35", name: "Santorini Gold", nameAr: "سانتوريني الذهبية", priceCoins: 260},
  {id: "background__wv_bg_36", themeId: "wv_bg_36", name: "Castle of Dawn", nameAr: "قلعة الفجر", priceCoins: 340},
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
const retiredBackgroundIds = [
  "background__golden_vip_glow",
  "background__royal_emerald_motion",
  "background__aurora_world",
  "background__galaxy_talk",
  "background__crystal_blue_luxury",
  "background__velvet_night",
];

for (const id of retiredBackgroundIds) {
  const ref = db.doc(`store_items/${id}`);
  const snapshot = await ref.get();
  if (snapshot.exists) {
    await ref.set({active: false, retiredFromCatalog: true}, {merge: true});
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