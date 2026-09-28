/**
 * Monetary policy lives in economy_config/current, not in the client or rules.
 * This module is pure so amounts can be regression tested without Firebase.
 */
const requiredPositive = [
  "coinsPerUsd", "diamondUsdValue", "giftLevelPointsPerCoin",
];
const requiredPercent = [
  "receiverSharePercent", "withdrawalFeePercent", "exchangeBonusPercent",
  "webCardBonusPercent", "firstRechargeBonusPercent",
];
const requiredNonnegativeIntegers = ["holdDays"];
const requiredPositiveIntegers = [
  "minWithdrawalDiamonds", "minExchangeDiamonds", "giftingDailyCoinLimit",
];
export function requireLiveEconomy(config) {
  if (!config || config.enabled !== true) {
    throw Object.assign(new Error("Economy not enabled."), {status: 503});
  }
  // Even a mistakenly enabled catalog cannot activate monetary routes before
  // the owner-only wallet/public-profile cutover and reconciliation.
  if (config.walletPrivacyCutoverComplete !== true) {
    throw Object.assign(
      new Error("Private wallet security cutover is not verified."),
      {status: 503},
    );
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
  for (const field of requiredPositiveIntegers) {
    if (!Number.isSafeInteger(config[field]) || config[field] <= 0) {
      throw Object.assign(new Error(`Invalid economy_config/${field}`), {status: 503});
    }
  }
  if (typeof config.purchaseDailyUsdLimit !== "number" ||
      !Number.isFinite(config.purchaseDailyUsdLimit) ||
      config.purchaseDailyUsdLimit <= 0 ||
      !Array.isArray(config.payoutWindows) ||
      config.payoutWindows.length !== 2 ||
      config.payoutWindows[0] === config.payoutWindows[1] ||
      !config.payoutWindows.every(day =>
        Number.isSafeInteger(day) && day >= 1 && day <= 28) ||
      !Array.isArray(config.withdrawalMethods) ||
      config.withdrawalMethods.length === 0 ||
      !config.withdrawalMethods.every(method =>
        ["paypal", "payoneer", "bank", "local_wallet"].includes(method))) {
    throw Object.assign(new Error("Economy limit or payout setup incomplete."), {status: 503});
  }
  if (config.minWithdrawalDiamonds === 0 || config.minExchangeDiamonds === 0 ||
      config.giftingDailyCoinLimit === 0 ||
      typeof config.purchaseDailyUsdLimit !== "number" ||
      !Number.isFinite(config.purchaseDailyUsdLimit) ||
      config.purchaseDailyUsdLimit <= 0 ||
      !Array.isArray(config.payoutWindows) ||
      config.payoutWindows.length !== 2 ||
      !config.payoutWindows.every(day => Number.isSafeInteger(day) &&
        day >= 1 && day <= 28) ||
      config.payoutWindows[0] === config.payoutWindows[1] ||
      !Array.isArray(config.withdrawalMethods) ||
      config.withdrawalMethods.length === 0 ||
      !config.withdrawalMethods.every(method =>
        ["paypal", "payoneer", "bank", "local_wallet"].includes(method))) {
    throw Object.assign(new Error("Incomplete approved economy configuration."),
      {status: 503});
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

/** Store-verified purchases only: no policy math is performed on a device. */
export function calculatePurchaseCredit({config, baseCoins, platform, firstRecharge}) {
  requireLiveEconomy(config);
  if (!Number.isSafeInteger(baseCoins) || baseCoins <= 0 ||
      !["android", "ios", "web"].includes(platform)) {
    throw Object.assign(new Error("Invalid purchase."), {status: 400});
  }
  const webPercent = platform === "web" ? config.webCardBonusPercent : 0;
  const firstPercent = firstRecharge ? config.firstRechargeBonusPercent : 0;
  if (firstPercent != null && (typeof firstPercent !== "number" ||
      !Number.isFinite(firstPercent) || firstPercent < 0 ||
      firstPercent > 100)) {
    throw Object.assign(new Error("Invalid first recharge promotion."), {status: 503});
  }
  const bonusCoins = Math.floor(
    baseCoins * (webPercent + (firstPercent ?? 0)) / 100,
  );
  const totalCoins = baseCoins + bonusCoins;
  if (!Number.isSafeInteger(totalCoins)) {
    throw Object.assign(new Error("Coin amount exceeds limits."), {status: 400});
  }
  return {baseCoins, bonusCoins, totalCoins};
}
