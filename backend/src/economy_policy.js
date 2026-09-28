/**
 * Monetary policy lives in economy_config/current, not in the client or rules.
 * This module is pure so amounts can be regression tested without Firebase.
 */
const requiredPositive = [
  "coinsPerUsd", "diamondUsdValue", "giftLevelPointsPerCoin",
];
const requiredPercent = [
  "receiverSharePercent", "withdrawalFeePercent", "exchangeBonusPercent",
  "webCardBonusPercent",
];
const requiredNonnegativeIntegers = [
  "holdDays", "minWithdrawalDiamonds", "minExchangeDiamonds",
];
export function requireLiveEconomy(config) {
  if (!config || config.enabled !== true) {
    throw Object.assign(new Error("Economy not enabled."), {status: 503});
  }
  for (const field of requiredPositive) {
    if (typeof config[field] !== "number" ||
        !Number.isFinite(config[field]) || config[field] <= 0) {
      throw Object.assign(new Error(`Invalid economy_config/${field}`), {status: 503});
    }
  }
  for (const field of requiredPercent) {
    if (typeof config[field] !== "number" ||
        !Number.isFinite(config[field]) || config[field] < 0 ||
        config[field] > 100) {
      throw Object.assign(new Error(`Invalid economy_config/${field}`), {status: 503});
    }
  }
  for (const field of requiredNonnegativeIntegers) {
    if (!Number.isSafeInteger(config[field]) || config[field] < 0) {
      throw Object.assign(new Error(`Invalid economy_config/${field}`), {status: 503});
    }
  }
  return config;
}
export function calculateGiftSettlement({
  config, priceCoins, quantity, freeGiftBalance,
}) {
  requireLiveEconomy(config);
  if (!Number.isSafeInteger(priceCoins) || priceCoins <= 0 ||
      !Number.isSafeInteger(quantity) || quantity <= 0 ||
      !Number.isSafeInteger(freeGiftBalance) || freeGiftBalance < 0) {
    throw Object.assign(new Error("Invalid gift request."), {status: 400});
  }
  const freeUnits = Math.min(quantity, freeGiftBalance);
  const chargedUnits = quantity - freeUnits;
  const chargedCoins = chargedUnits * priceCoins;
  if (!Number.isSafeInteger(chargedCoins)) {
    throw Object.assign(new Error("Gift amount exceeds safe limits."), {status: 400});
  }
  const giftLevelPoints = chargedCoins * config.giftLevelPointsPerCoin;
  // Only paid gifts create redeemable value. Free promotional gifts do not
  // create withdrawal liability unless policy explicitly provides otherwise.
  const receiverUsd = chargedCoins / config.coinsPerUsd *
    (config.receiverSharePercent / 100);
  const pendingDiamonds = Math.floor(receiverUsd / config.diamondUsdValue);
  if (!Number.isSafeInteger(pendingDiamonds) ||
      !Number.isSafeInteger(giftLevelPoints)) {
    throw Object.assign(new Error("Gift settlement is not representable."), {status: 400});
  }
  return {
    freeUnits, chargedCoins, giftLevelPoints, pendingDiamonds,
  };
}
