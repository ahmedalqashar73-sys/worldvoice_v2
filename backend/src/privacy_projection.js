/**
 * Conservative staged projection. It creates PRIVATE finance snapshots and
 * PUBLIC allowlisted profiles without deleting or rewriting legacy users.
 * This file is NOT a live-wallet read/write switch.
 */
export const PRIVATE_WALLET_FIELDS = Object.freeze([
  "coins", "diamonds", "diamondsPending", "diamondsOnHold",
  "giftSentPoints", "giftReceivedPoints", "giftLevelPoints",
  "purchasedCoins", "quizCoinsEarned", "walletBalance",
  "withdrawableDiamonds", "walletDebtCoins", "walletFrozen",
  "payoutFrozen", "diamondsReserved", "firstRechargeUsed",
  "payoutFreezeReason", "identityVerified", "lastGiftRoomId",
  "lastGiftEventId", "vipExpiresAt",
]);

const PUBLIC_FIELDS = Object.freeze([
  "displayName", "username", "customId", "photoUrl", "coverUrl",
  "bio", "country", "countryCode", "gender", "nativeLanguage",
  "nativeLanguageCode", "learningLanguages", "learningLanguageCodes",
  "languageLevel", "interests", "profession", "professionKey",
  "travel", "learningGoals", "voiceBioUrl", "isOnline",
  "lastActiveAt", "lastSeenAt", "isVip",
]);

function pick(source, keys) {
  const target = {};
  for (const key of keys) {
    if (Object.prototype.hasOwnProperty.call(source, key)
        && source[key] !== undefined) {
      target[key] = source[key];
    }
  }
  return target;
}

export function projectPrivateWallet(source) {
  if (!source || typeof source !== "object" || Array.isArray(source)) {
    throw new TypeError("Existing user profile must be an object.");
  }
  const wallet = pick(source, PRIVATE_WALLET_FIELDS);
  for (const key of [
    "coins", "diamonds", "diamondsPending", "diamondsOnHold",
    "walletDebtCoins", "diamondsReserved", "purchasedCoins",
  ]) {
    const value = wallet[key] ?? 0;
    if (!Number.isSafeInteger(value) || value < 0) {
      throw new Error("Invalid legacy wallet field: " + key);
    }
    wallet[key] = value;
  }
  wallet.schemaVersion = 1;
  return wallet;
}

export function projectPublicProfile(source, uid) {
  if (typeof uid !== "string" || uid.length === 0) {
    throw new Error("A stable Firebase UID is required.");
  }
  if (!source || typeof source !== "object" || Array.isArray(source)) {
    throw new TypeError("Existing user profile must be an object.");
  }
  const result = {uid, ...pick(source, PUBLIC_FIELDS), schemaVersion: 1};
  // City is PRIVATE by default. It appears only on explicit opt-in.
  if (source.hideCity === false && typeof source.city === "string" &&
      source.city.trim().length > 0) {
    result.city = source.city.trim();
  }
  // Full date of birth is never included in the public projection.
  // An age may be calculated in the client later if consent/policy permits.
  return result;
}

export function assertPublicProjectionSafe(profile) {
  const permitted = new Set(["uid", "schemaVersion", "city", ...PUBLIC_FIELDS]);
  for (const key of Object.keys(profile)) {
    if (!permitted.has(key)) {
      throw new Error("Unexpected public profile field: " + key);
    }
  }
  if (Object.keys(profile).some(key => PRIVATE_WALLET_FIELDS.includes(key))) {
    throw new Error("Public profile contains private wallet fields.");
  }
  return true;
}
