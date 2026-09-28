// WorldVoice economy arithmetic lives here, not in Flutter or Firestore rules.
// Missing/malformed configuration MUST fail closed: do not guess live prices.
const requiredRates = [
  "coinsPerUsd", "receiverSharePercent", "diamondUsdValue",
  "withdrawalFeePercent", "minWithdrawalDiamonds", "holdDays",
  "giftLevelPointsPerCoin", "exchangeBonusPercent",
  "minExchangeDiamonds", "cardBonusPercent", "firstRechargeBonusPercent",
  "dailySendLimitCoins", "dailyPurchaseLimitUsd", "withdrawalWindowDays",
];
const int = (n) => typeof n === "number" && Number.isSafeInteger(n);
const positive = (n) => typeof n === "number" && Number.isFinite(n) && n > 0;
const percent = (n) => typeof n === "number" && Number.isFinite(n) && n >= 0 && n <= 100;
export function economyError(message, status = 409) {
  return Object.assign(new Error(message), { status });
}
export function validateEconomy(data) {
  if (!data || typeof data !== "object") throw economyError("economy_config/global is missing.");
  const missing = requiredRates.filter((key) => data[key] == null);
  if (missing.length) throw economyError("economy_config is missing: " + missing.join(", "));
  for (const key of ["coinsPerUsd", "diamondUsdValue"])
    if (!positive(data[key])) throw economyError(key + " must be positive.");
  for (const key of ["receiverSharePercent", "withdrawalFeePercent", "exchangeBonusPercent"])
    if (!percent(data[key])) throw economyError(key + " must be a percent.");
  for (const key of ["minWithdrawalDiamonds", "holdDays", "giftLevelPointsPerCoin"])
    if (!int(data[key]) || data[key] < 0) throw economyError(key + " must be a nonnegative integer.");
  for (const key of ["cardBonusPercent", "firstRechargeBonusPercent"])
    if (data[key] != null && !percent(data[key])) throw economyError(key + " must be a percent.");
  for (const key of ["minExchangeDiamonds", "dailySendLimitCoins", "dailyPurchaseLimitUsd"]) {
    if (data[key] != null && (!int(data[key]) || data[key] < 0))
      throw economyError(key + " must be a nonnegative integer.");
  }
  if (data.withdrawalWindowDays != null &&
      (!Array.isArray(data.withdrawalWindowDays) ||
       data.withdrawalWindowDays.length !== 2 ||
       data.withdrawalWindowDays.some((d) => !int(d) || d < 1 || d > 31)))
    throw economyError("withdrawalWindowDays must contain two month dates.");
  if (data.enabled !== true) throw economyError("Economy is not enabled by the administrator.", 503);
  return data;
}
export function giftQuote(config, priceCoins, quantity) {
  validateEconomy(config);
  if (!int(priceCoins) || priceCoins <= 0 || !int(quantity) || quantity <= 0 || quantity > 100)
    throw economyError("Invalid gift price or quantity.", 400);
  const coins = priceCoins * quantity;
  if (!Number.isSafeInteger(coins)) throw economyError("Gift price overflow.", 400);
  // Exchange conversions floor to whole diamonds. The gift's displayed USD
  // value is for transparency and does NOT guarantee a withdrawal amount.
  const receiverUsd = coins / config.coinsPerUsd * config.receiverSharePercent / 100;
  const diamonds = Math.floor(receiverUsd / config.diamondUsdValue + Number.EPSILON);
  return {
    coins,
    diamonds,
    receiverUsd,
    giftLevelPoints: coins * config.giftLevelPointsPerCoin,
  };
}
export function coinCredit(config, baseCoins, { webCard = false, firstRecharge = false } = {}) {
  validateEconomy(config);
  if (!int(baseCoins) || baseCoins <= 0) throw economyError("Invalid coin product.", 400);
  const cardBonus = webCard ? Math.floor(baseCoins * (config.cardBonusPercent ?? 0) / 100) : 0;
  const firstBonus = firstRecharge ?
    Math.floor(baseCoins * (config.firstRechargeBonusPercent ?? 0) / 100) : 0;
  return { coins: baseCoins + cardBonus + firstBonus, baseCoins, cardBonus, firstBonus };
}
export function withdrawalQuote(config, diamonds) {
  validateEconomy(config);
  if (!int(diamonds) || diamonds < config.minWithdrawalDiamonds)
    throw economyError("WITHDRAWAL_MIN_NOT_MET", 400);
  const grossUsd = diamonds * config.diamondUsdValue;
  const feeUsd = Math.round(grossUsd * config.withdrawalFeePercent) / 100;
  return { diamonds, grossUsd, feeUsd, netUsd: Math.max(0, grossUsd - feeUsd) };
}
export function exchangeQuote(config, diamonds) {
  validateEconomy(config);
  if (!int(diamonds) || diamonds < (config.minExchangeDiamonds ?? Number.MAX_SAFE_INTEGER))
    throw economyError("EXCHANGE_MIN_NOT_MET", 400);
  const baseCoins = Math.floor(diamonds * config.diamondUsdValue * config.coinsPerUsd);
  const bonusCoins = Math.floor(baseCoins * config.exchangeBonusPercent / 100);
  return { diamonds, baseCoins, bonusCoins, totalCoins: baseCoins + bonusCoins };
}
export function positiveBalance(value) {
  if (value == null) return 0;
  if (!int(value) || value < 0) throw economyError("Stored wallet balance is invalid.", 503);
  return value;
}
