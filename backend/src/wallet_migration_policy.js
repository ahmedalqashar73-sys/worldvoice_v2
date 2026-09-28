/**
 * Explicit allow-list public identity projection and private wallet snapshot.
 * No direct copy/spread of a users/{uid} document into public_profiles.
 * This module has no Firestore side-effects so it can be tested in isolation.
 */
export const PRIVATE_FINANCE_FIELDS = Object.freeze([
  "coins", "diamonds", "diamondsPending", "diamondsReserved", "purchasedCoins",
  "quizCoinsEarned", "walletDebtCoins", "walletFrozen", "payoutFrozen",
  "payoutFreezeReason", "firstRechargeUsed", "identityVerified",
]);

export const PUBLIC_PROFILE_FIELDS = Object.freeze([
  "uid", "displayName", "username", "customId", "photoUrl",
  "bio", "voiceBioUrl", "country", "countryCode", "gender",
  "nativeLanguage", "nativeLanguageCode", "learningLanguages",
  "learningLanguageCodes", "interests", "profession",
  "hideCity", "isOnline", "lastActiveAt", "lastSeenAt",
  "followersCount", "followingCount",
]);

const nonNegativeInteger = (value, field) => {
  if (value == null) return 0;
  if (!Number.isSafeInteger(value) || value < 0) {
    throw new Error(`Invalid legacy wallet field: ${field}`);
  }
  return value;
};

export function buildPrivateWallet(data) {
  if (!data || typeof data !== "object") {
    throw new Error("Legacy user profile not found.");
  }
  return {
    schemaVersion: 2,
    coins: nonNegativeInteger(data.coins, "coins"),
    diamonds: nonNegativeInteger(data.diamonds, "diamonds"),
    diamondsPending: nonNegativeInteger(data.diamondsPending, "diamondsPending"),
    diamondsReserved: nonNegativeInteger(data.diamondsReserved, "diamondsReserved"),
    purchasedCoins: nonNegativeInteger(data.purchasedCoins, "purchasedCoins"),
    quizCoinsEarned: nonNegativeInteger(data.quizCoinsEarned, "quizCoinsEarned"),
    walletDebtCoins: nonNegativeInteger(data.walletDebtCoins, "walletDebtCoins"),
    walletFrozen: data.walletFrozen === true,
    payoutFrozen: data.payoutFrozen === true,
    payoutFreezeReason: typeof data.payoutFreezeReason === "string" ?
      data.payoutFreezeReason.slice(0, 500) : "",
    firstRechargeUsed: data.firstRechargeUsed === true,
    identityVerified: data.identityVerified === true,
  };
}

export function buildPublicProfile(data, uid) {
  if (!uid || typeof uid !== "string") throw new Error("uid is required.");
  if (!data || typeof data !== "object") throw new Error("Profile is required.");
  const publicData = {uid};
  for (const field of PUBLIC_PROFILE_FIELDS) {
    if (field === "uid" || field === "hideCity") continue;
    const value = data[field];
    if (value != null) publicData[field] = value;
  }
  // With no prior privacy preference, never expose a city by default.
  const displayCity = data.hideCity === false && typeof data.city === "string" &&
    data.city.trim().length > 0;
  publicData.hideCity = !displayCity;
  if (displayCity) publicData.city = data.city.trim().slice(0, 120);

  // Expose an age number rather than an exact date of birth. It is computed
  // once during migration and must be refreshed by future profile writes.
  const birth = data.birthDate?.toDate?.() ??
    (data.birthDate instanceof Date ? data.birthDate : null);
  if (birth instanceof Date && !Number.isNaN(birth.getTime())) {
    const today = new Date();
    let age = today.getUTCFullYear() - birth.getUTCFullYear();
    if (today.getUTCMonth() < birth.getUTCMonth() ||
        (today.getUTCMonth() === birth.getUTCMonth() &&
         today.getUTCDate() < birth.getUTCDate())) age--;
    if (age >= 0 && age < 130) publicData.age = age;
  }
  return publicData;
}
