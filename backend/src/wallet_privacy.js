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
 * A previous migration copy is NOT proof of a current balance. Detect drift,
 * preserve the existing ledger and require manual reconciliation on mismatch.
 * Dates and Firestore Timestamps must compare by value, not object identity.
 */
function stable(value) {
  if (value && typeof value.toMillis === "function") {
    return {timestampMs: value.toMillis()};
  }
  if (Array.isArray(value)) return value.map(stable);
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value).sort(([a], [b]) => a.localeCompare(b))
        .map(([key, item]) => [key, stable(item)]),
    );
  }
  return value;
}
function equivalent(a, b) {
  return JSON.stringify(stable(a)) === JSON.stringify(stable(b));
}
export function walletCopyMatches(legacyUser, walletCopy) {
  return equivalent(
    extractPrivateWallet(legacyUser),
    extractPrivateWallet(walletCopy),
  );
}
export function publicCopyMatches(uid, legacyUser, existing) {
  const projected = sanitizedPublicProfile(uid, legacyUser);
  const permitted = new Set([...Object.keys(projected),
    "migrationVersion", "snapshotAt"]);
  // Never accept an existing public projection with a secret extra key.
  if (Object.keys(existing).some(key => !permitted.has(key))) return false;
  const actual = Object.fromEntries(
    Object.keys(projected).filter(key => existing[key] !== undefined)
      .map(key => [key, existing[key]]),
  );
  return equivalent(projected, actual);
}
