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
 * Read-only cutover audit after legacy financial writes have been FROZEN.
 * This is deliberately a strict comparison: discrepancies prevent cutover.
 * Only error categories are returned; never emit user balances or identity.
 */
export function auditPrivacySnapshot(uid, legacy, walletDoc, publicDoc) {
  const issues = [];
  let expectedWallet;
  try {
    expectedWallet = extractPrivateWallet(legacy);
  } catch (_) {
    issues.push("invalid_legacy_wallet");
  }
  const safeProfile = sanitizedPublicProfile(uid, legacy);
  if (!walletDoc) {
    issues.push("missing_private_wallet");
  } else if (expectedWallet) {
    for (const [field, value] of Object.entries(expectedWallet)) {
      if (!Object.hasOwn(walletDoc, field) ||
          JSON.stringify(walletDoc[field]) !== JSON.stringify(value)) {
        issues.push("wallet_mismatch");
        break;
      }
    }
  }
  if (!publicDoc) {
    issues.push("missing_public_profile");
  } else {
    // The projection may have only these two migration metadata fields.
    const safeKeys = new Set([
      ...Object.keys(safeProfile), "migrationVersion", "snapshotAt",
    ]);
    if (Object.keys(publicDoc).some(field => !safeKeys.has(field))) {
      issues.push("unsafe_public_profile_field");
    }
    if (Object.entries(safeProfile).some(([field, value]) =>
      !Object.hasOwn(publicDoc, field) ||
      JSON.stringify(publicDoc[field]) !== JSON.stringify(value))) {
      issues.push("public_profile_mismatch");
    }
  }
  return [...new Set(issues)];
}
