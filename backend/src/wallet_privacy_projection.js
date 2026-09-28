/**
 * Explicit projections: never spread a users/{uid} document into public
 * profiles. Keep private finance out of any client-readable profile.
 * This module contains no Firebase dependency and is regression-testable.
 */
export const PRIVATE_WALLET_FIELDS = Object.freeze([
  "coins", "diamonds", "diamondsPending", "diamondsOnHold",
  "diamondsReserved", "walletDebtCoins", "walletFrozen", "payoutFrozen",
  "payoutFreezeReason", "firstRechargeUsed", "identityVerified",
  "purchasedCoins", "quizCoinsEarned",
  "giftSentPoints", "giftReceivedPoints", "giftLevelPoints",
]);

export const PUBLIC_PROFILE_FIELDS = Object.freeze([
  "uid", "displayName", "name", "username", "customId", "photoURL",
  "photoUrl", "profileImageUrl", "countryCode", "nativeLanguageCode",
  "learningLanguageCodes", "hobbies", "profession", "bio",
]);

const NONNEGATIVE_WALLET_AMOUNTS = new Set([
  "coins", "diamonds", "diamondsPending", "diamondsOnHold",
  "diamondsReserved", "walletDebtCoins", "purchasedCoins",
  "quizCoinsEarned", "giftSentPoints", "giftReceivedPoints", "giftLevelPoints",
]);

export function projectPrivateWallet(user, uid) {
  if (!user || typeof user !== "object" || typeof uid !== "string" || !uid) {
    throw new TypeError("Expected a user profile and nonempty UID.");
  }
  const result = {userId: uid, migrationVersion: 1};
  for (const key of PRIVATE_WALLET_FIELDS) {
    if (!Object.hasOwn(user, key)) continue;
    const value = user[key];
    if (NONNEGATIVE_WALLET_AMOUNTS.has(key) &&
        (!Number.isSafeInteger(value) || value < 0)) {
      throw new Error(`Invalid legacy wallet field ${key} for ${uid}; review manually.`);
    }
    if (["walletFrozen", "payoutFrozen", "firstRechargeUsed",
      "identityVerified"].includes(key) && typeof value !== "boolean") {
      throw new Error(`Invalid wallet flag ${key} for ${uid}; review manually.`);
    }
    result[key] = value;
  }
  return result;
}

export function projectPublicProfile(user, uid) {
  if (!user || typeof user !== "object" || typeof uid !== "string" || !uid) {
    throw new TypeError("Expected a user profile and nonempty UID.");
  }
  const result = {uid, projectionVersion: 1};
  for (const key of PUBLIC_PROFILE_FIELDS) {
    if (key === "uid" || !Object.hasOwn(user, key)) continue;
    const value = user[key];
    if (value !== undefined && value !== null) result[key] = value;
  }
  // Never expose the actual city or date of birth in the new public index.
  return result;
}
