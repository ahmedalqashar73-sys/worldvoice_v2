// A staging-only, explicit projection. Do not expose the legacy users/{uid}
// document to other users once the entire application has cut over.
export const PRIVATE_WALLET_FIELDS = Object.freeze([
  "coins", "diamonds", "diamondsPending", "diamondsReserved",
  "purchasedCoins", "quizCoinsEarned", "walletDebtCoins",
  "walletFrozen", "payoutFrozen", "payoutFreezeReason",
  "identityVerified", "firstRechargeUsed",
]);

// This is a positive allowlist. Never clone arbitrary user properties into a
// public document: legacy user docs can contain finance and private settings.
export const PUBLIC_PROFILE_FIELDS = Object.freeze([
  "uid", "displayName", "name", "username", "customId",
  "photoUrl", "photoURL", "profileImageUrl", "gender",
  "countryCode", "nativeLanguageCode", "learningLanguageCodes",
  "languageLevel", "bio", "aboutMe", "hobbies",
  "profession", "professionName", "travel", "age",
]);

const MONEY_NONNEGATIVE = new Set([
  "coins", "diamonds", "diamondsPending", "diamondsReserved",
  "purchasedCoins", "quizCoinsEarned", "walletDebtCoins",
]);
const FLAGS = new Set([
  "walletFrozen", "payoutFrozen", "identityVerified", "firstRechargeUsed",
]);

export function projectPrivateWallet(legacy = {}) {
  const wallet = {};
  for (const field of PRIVATE_WALLET_FIELDS) {
    const value = legacy[field];
    if (value === undefined || value === null) continue;
    if (MONEY_NONNEGATIVE.has(field)) {
      if (!Number.isSafeInteger(value) || value < 0) {
        throw new Error(`Invalid legacy wallet field: ${field}`);
      }
    } else if (FLAGS.has(field)) {
      if (typeof value !== "boolean") {
        throw new Error(`Invalid legacy wallet flag: ${field}`);
      }
    } else if (field === "payoutFreezeReason") {
      if (typeof value !== "string" || value.length > 1000) {
        throw new Error("Invalid legacy payout freeze reason");
      }
    }
    wallet[field] = value;
  }
  return wallet;
}

export function projectPublicProfile(uid, legacy = {}) {
  if (typeof uid !== "string" || !uid.trim()) {
    throw new Error("Missing profile user ID");
  }
  const publicData = {uid};
  for (const field of PUBLIC_PROFILE_FIELDS) {
    if (field === "uid") continue;
    if (Object.prototype.hasOwnProperty.call(legacy, field) &&
        legacy[field] !== undefined && legacy[field] !== null) {
      publicData[field] = legacy[field];
    }
  }
  return publicData;
}
