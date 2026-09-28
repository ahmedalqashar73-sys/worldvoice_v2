// Phase 1: non-destructive private-wallet migration helpers.
// Never derive profile publication from a blacklist: allow only safe fields.
const publicFields = [
  "displayName", "username", "bio", "country", "gender",
  "photoUrl", "coverUrl", "nativeLanguageCode", "nativeLanguage",
  "learningLanguageCodes", "learningLanguages", "languageLevel",
  "profession", "professionKey", "travel", "learningGoals", "interests",
  "followersCount", "followingCount", "profileCompleted",
  "isPartner", "isVerified", "giftLevel", "isVip",
];
const financialFields = [
  "coins", "diamonds", "diamondsPending", "diamondsOnHold",
  "diamondsReserved", "purchasedCoins", "quizCoinsEarned",
  "giftSentPoints", "giftReceivedPoints", "walletDebtCoins",
  "walletFrozen", "payoutFrozen", "payoutFreezeReason",
  "withdrawableDiamonds", "walletBalance", "firstRechargeUsed",
  "identityVerified", "vipExpiresAt",
];
const nonnegativeIntegers = new Set([
  "coins", "diamonds", "diamondsPending", "diamondsOnHold",
  "diamondsReserved", "purchasedCoins", "quizCoinsEarned",
  "giftSentPoints", "giftReceivedPoints", "withdrawableDiamonds",
]);

export function sanitizedPublicProfile(uid, raw = {}) {
  if (typeof uid !== "string" || !uid) throw new Error("Missing UID");
  const profile = {uid};
  for (const field of publicFields) {
    if (raw[field] !== undefined && raw[field] !== null) {
      profile[field] = raw[field];
    }
  }
  // Never include raw city or birthDate: both are private by default.
  // An explicit city visibility feature can update this projection later.
  return profile;
}

export function extractPrivateWallet(raw = {}) {
  const wallet = {};
  for (const field of financialFields) {
    if (raw[field] !== undefined && raw[field] !== null) {
      wallet[field] = raw[field];
    }
  }
  for (const field of nonnegativeIntegers) {
    if (wallet[field] !== undefined &&
        (!Number.isSafeInteger(wallet[field]) || wallet[field] < 0)) {
      throw new Error("Invalid legacy financial field: " + field);
    }
  }
  if (wallet.walletDebtCoins !== undefined &&
      (!Number.isSafeInteger(wallet.walletDebtCoins) ||
       wallet.walletDebtCoins < 0)) {
    throw new Error("Invalid legacy wallet debt");
  }
  return wallet;
}

/**
 * Non-destructive migration consistency check. Never overwrite a balance
 * when a prior staging snapshot no longer matches the legacy source.
 */
export function privateSnapshotMatches(existing = {}, projected = {}) {
  const same = (a, b) =>
    a?.toMillis && b?.toMillis ? a.toMillis() === b.toMillis() : a === b;
  return Object.entries(projected).every(([key, value]) =>
    Object.hasOwn(existing, key) && same(existing[key], value));
}
