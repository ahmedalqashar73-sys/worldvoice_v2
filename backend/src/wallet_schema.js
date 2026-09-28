// Private balance document. Ledger and legacy inventory remain in the
// existing users/{uid} subcollections so old transaction IDs are preserved.
export const walletRef = (db, uid) => db.collection("wallets").doc(uid);

export const walletFields = Object.freeze([
  "coins", "diamonds", "diamondsPending", "diamondsOnHold",
  "diamondsReserved", "purchasedCoins", "quizCoinsEarned",
  "giftSentPoints", "giftReceivedPoints", "giftLevelPoints", "giftLevel",
  "walletDebtCoins", "walletFrozen", "payoutFrozen",
  "payoutFreezeReason", "firstRechargeUsed", "identityVerified",
  "vipExpiresAt", "withdrawableDiamonds", "walletBalance",
  "lastGiftRoomId", "lastGiftEventId",
]);

export const publicFields = Object.freeze([
  "uid", "displayName", "username", "bio", "country", "gender", "photoUrl",
  "coverUrl", "nativeLanguageCode", "nativeLanguage",
  "learningLanguageCodes", "learningLanguages", "languageLevel",
  "professionKey", "profession", "travel", "learningGoals", "interests",
  "voiceBioUrl", "isPartner", "isOnline", "lastActiveAt", "lastSeenAt",
  "followersCount", "followingCount", "hideCity", "city",
  "profileCompleted",
]);

const safeNonnegative = value => Number.isSafeInteger(value) && value >= 0;
export function projectWallet(data = {}) {
  const result = {schemaVersion: 1};
  const integerFields = [
    "coins", "diamonds", "diamondsPending", "diamondsOnHold",
    "diamondsReserved", "purchasedCoins", "quizCoinsEarned",
    "giftSentPoints", "giftReceivedPoints", "giftLevelPoints", "giftLevel",
    "walletDebtCoins",
  ];
  for (const name of integerFields) {
    const value = data[name] ?? 0;
    if (!safeNonnegative(value)) {
      throw new Error("Invalid legacy wallet field: " + name);
    }
    result[name] = value;
  }
  for (const name of ["walletFrozen", "payoutFrozen", "firstRechargeUsed",
    "identityVerified"]) result[name] = data[name] === true;
  if (data.vipExpiresAt != null) result.vipExpiresAt = data.vipExpiresAt;
  if (data.payoutFreezeReason != null) {
    result.payoutFreezeReason = String(data.payoutFreezeReason);
  }
  return result;
}

export function projectPublicProfile(data = {}, now = new Date()) {
  const publicData = Object.fromEntries(publicFields
    .filter(key => Object.hasOwn(data, key)).map(key => [key, data[key]]));
  const dob = data.birthDate?.toDate?.() || data.birthDate;
  if (dob instanceof Date && !Number.isNaN(dob.getTime())) {
    let age = now.getUTCFullYear() - dob.getUTCFullYear();
    if (now.getUTCMonth() < dob.getUTCMonth() ||
        (now.getUTCMonth() === dob.getUTCMonth() &&
          now.getUTCDate() < dob.getUTCDate())) age--;
    if (age >= 0 && age <= 120) publicData.ageYears = age;
  }
  if (data.hideCity === true) delete publicData.city;
  return publicData;
}

export function requireMigratedWallet(snapshot) {
  if (!snapshot?.exists || snapshot.data()?.schemaVersion !== 1) {
    throw Object.assign(new Error(
      "Private wallet is not migrated or initialized; money is disabled.",
    ), {status: 503});
  }
  return snapshot.data();
}
