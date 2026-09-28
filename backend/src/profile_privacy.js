/**
 * Explicit allowlists for the staged public-profile/private-wallet split.
 * NEVER spread a legacy user document into a public record.
 * No Firestore writes happen in this pure module.
 */
export const PUBLIC_PROFILE_FIELDS = Object.freeze([
  "uid", "displayName", "username", "country", "countryCode",
  "gender", "nativeLanguage", "nativeLanguageCode", "learningLanguages",
  "learningLanguageCodes", "photoUrl", "coverUrl", "bio", "voiceBioUrl",
  "interests", "profession", "professionKey", "languageLevel",
  "learningGoals", "travel", "followersCount", "followingCount",
  "isPartner", "isVerified", "isOnline", "lastActiveAt", "lastSeenAt",
  "hideCity", "profileCompleted",
]);

export const PRIVATE_WALLET_FIELDS = Object.freeze([
  "coins", "purchasedCoins", "diamonds", "diamondsPending",
  "diamondsReserved", "walletDebtCoins", "walletFrozen", "payoutFrozen",
  "payoutFreezeReason", "firstRechargeUsed", "quizCoinsEarned",
  "giftLevel", "giftLevelPoints", "giftSentPoints", "giftReceivedPoints",
]);

const hasOwn = (object, field) =>
  Object.prototype.hasOwnProperty.call(object, field);

/** Safe to read by signed-in WorldVoice members. */
export function toPublicProfile(userId, legacy = {}) {
  if (!userId || typeof userId !== "string") {
    throw new TypeError("A valid user ID is required.");
  }
  const publicData = {uid: userId};
  for (const key of PUBLIC_PROFILE_FIELDS) {
    if (key !== "uid" && hasOwn(legacy, key) && legacy[key] !== undefined) {
      publicData[key] = legacy[key];
    }
  }
  // City must never be published unless the owner explicitly opted in.
  if (legacy.hideCity === false && typeof legacy.city === "string" &&
      legacy.city.trim()) {
    publicData.city = legacy.city.trim();
  }
  // Do not publish full DOB, email, wallet values, account roles or KYC.
  return publicData;
}

/** Initial private copy; all backend financial operations need explicit cutover. */
export function toPrivateWallet(userId, legacy = {}) {
  if (!userId || typeof userId !== "string") {
    throw new TypeError("A valid user ID is required.");
  }
  const privateData = {uid: userId};
  for (const key of PRIVATE_WALLET_FIELDS) {
    if (hasOwn(legacy, key) && legacy[key] !== undefined) {
      privateData[key] = legacy[key];
    }
  }
  return privateData;
}

export function hasPrivateWalletFields(record = {}) {
  return PRIVATE_WALLET_FIELDS.some(key => hasOwn(record, key));
}

/** Never use existing private document values as a default for new credits. */
export function walletCopyMatches(existing, projected) {
  for (const key of PRIVATE_WALLET_FIELDS) {
    if (hasOwn(projected, key) &&
        (!hasOwn(existing || {}, key) ||
          existing[key] !== projected[key])) return false;
  }
  return existing?.uid === projected.uid;
}
