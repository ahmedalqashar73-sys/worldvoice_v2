/**
 * Explicit allowlists for the staged public-profile/private-wallet split.
 * The legacy users/{uid} document is still read by old app clients: writing
 * projections alone DOES NOT repair that access. Follow the gated rollout.
 */
export const PRIVATE_WALLET_FIELDS = Object.freeze([
  "coins", "diamonds", "diamondsPending", "diamondsOnHold",
  "diamondsReserved", "walletBalance", "withdrawableDiamonds",
  "purchasedCoins", "quizCoinsEarned", "walletDebtCoins",
  "giftSentPoints", "giftReceivedPoints", "giftLevelPoints", "giftLevel",
  "lastGiftRoomId", "lastGiftEventId", "walletFrozen", "payoutFrozen",
  "payoutFreezeReason", "firstRechargeUsed", "identityVerified",
  "vipExpiresAt",
]);

// A public projection must never use object spreading from the legacy record.
const PUBLIC_STRING_FIELDS = Object.freeze([
  "displayName", "name", "username", "customId", "country", "countryCode",
  "nativeLanguageCode", "nativeLanguage", "bio", "photoURL", "photoUrl",
  "coverUrl", "voiceBioUrl", "gender", "profession", "professionKey",
  "job", "languageLevel", "learningGoals", "travel",
]);
const PUBLIC_ARRAY_FIELDS = Object.freeze([
  "learningLanguageCodes", "learningLanguages", "hobbies", "interests",
  "learningGoals",
]);
const PUBLIC_BOOLEAN_FIELDS = Object.freeze([
  "profileCompleted", "isPartner", "isVerified", "isVip", "isOnline",
  "travel",
]);
const PUBLIC_INTEGER_FIELDS = Object.freeze([
  "followersCount", "followingCount", "giftLevel",
]);

export function projectPublicProfile(userId, source) {
  if (typeof userId !== "string" || !userId.trim() ||
      !source || typeof source !== "object" || Array.isArray(source)) {
    throw new TypeError("A valid user and profile are required.");
  }
  if (source.uid != null && source.uid !== userId) {
    throw new Error("Profile UID does not match its document.");
  }
  const output = {uid: userId};
  for (const field of PUBLIC_STRING_FIELDS) {
    const value = source[field];
    if (typeof value === "string" && value.length <= 3000) {
      output[field] = value;
    }
  }
  for (const field of PUBLIC_ARRAY_FIELDS) {
    const values = source[field];
    if (Array.isArray(values) && values.length <= 60 &&
        values.every(value => typeof value === "string" &&
            value.length <= 150)) {
      output[field] = [...values];
    }
  }
  for (const field of PUBLIC_BOOLEAN_FIELDS) {
    if (typeof source[field] === "boolean") output[field] = source[field];
  }
  for (const field of PUBLIC_INTEGER_FIELDS) {
    if (Number.isSafeInteger(source[field]) && source[field] >= 0) {
      output[field] = source[field];
    }
  }
  for (const field of ["lastActiveAt", "lastSeenAt"]) {
    const value = source[field];
    if (typeof value?.toMillis === "function") output[field] = value;
  }
  // City and full DOB remain hidden by default; do not publish either.
  if (Number.isSafeInteger(source.age) &&
      source.age >= 0 && source.age <= 120) {
    output.age = source.age;
  }
  return output;
}

const NONNEGATIVE_NUMERIC_WALLET_FIELDS = new Set([
  "coins", "diamonds", "diamondsPending", "diamondsOnHold",
  "diamondsReserved", "walletBalance", "withdrawableDiamonds",
  "purchasedCoins", "quizCoinsEarned", "walletDebtCoins",
  "giftSentPoints", "giftReceivedPoints", "giftLevelPoints", "giftLevel",
]);
const WALLET_BOOL_FIELDS = new Set([
  "walletFrozen", "payoutFrozen", "firstRechargeUsed", "identityVerified",
]);
const WALLET_STRING_FIELDS = new Set([
  "lastGiftRoomId", "lastGiftEventId", "payoutFreezeReason",
]);

export function extractLegacyWallet(source) {
  if (!source || typeof source !== "object" || Array.isArray(source)) {
    throw new TypeError("A legacy wallet source is required.");
  }
  const wallet = {};
  for (const field of PRIVATE_WALLET_FIELDS) {
    if (!Object.hasOwn(source, field) || source[field] == null) continue;
    const value = source[field];
    if (NONNEGATIVE_NUMERIC_WALLET_FIELDS.has(field)) {
      if (!Number.isSafeInteger(value) || value < 0) {
        throw new Error(`Invalid legacy balance: ${field}`);
      }
    } else if (WALLET_BOOL_FIELDS.has(field)) {
      if (typeof value !== "boolean") {
        throw new Error(`Invalid legacy wallet flag: ${field}`);
      }
    } else if (WALLET_STRING_FIELDS.has(field)) {
      if (typeof value !== "string" || value.length > 1000) {
        throw new Error(`Invalid legacy wallet metadata: ${field}`);
      }
    } else if (field === "vipExpiresAt") {
      // Firestore Timestamp (or null); never JSON-serialize or guess dates.
      if (typeof value?.toMillis !== "function") {
        throw new Error("Invalid legacy VIP expiration timestamp.");
      }
    }
    wallet[field] = value;
  }
  return wallet;
}


/** Reject stale pre-existing migration data. Never replace balances blindly. */
export function assertExistingProjectionMatches(expected, actual, label) {
  if (!actual || typeof actual !== "object" ||
      !expected || typeof expected !== "object") {
    throw new TypeError("Two migration projections are required.");
  }
  const fieldNames = new Set([...Object.keys(expected), ...Object.keys(actual)]);
  fieldNames.delete("migrationSource");
  fieldNames.delete("stagedAt");
  fieldNames.delete("migrationVersion");
  fieldNames.delete("snapshotAt");
  fieldNames.delete("legacySource");
  for (const field of fieldNames) {
    const left = expected[field];
    const right = actual[field];
    const normalize = value => {
      if (value?.toMillis && typeof value.toMillis === "function") {
        return value.toMillis();
      }
      return value;
    };
    const a = normalize(left);
    const b = normalize(right);
    const same = Array.isArray(a) && Array.isArray(b)
      ? a.length === b.length && a.every((value, index) => value === b[index])
      : a === b || (a == null && (b === 0 || b === false)) ||
          (b == null && (a === 0 || a === false));
    if (!same) {
      // Field names only: never include names, wallet amounts or other
      // personal values in migration logs or thrown errors.
      throw Object.assign(
        new Error(`Stale ${label} projection; reconcile before continuing.`),
        {code: "MIGRATION_RECONCILIATION_REQUIRED"},
      );
    }
  }
  return true;
}
