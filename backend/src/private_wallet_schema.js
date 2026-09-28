// Private wallet balance fields belong only in users/{uid}/private_wallet/summary.
// Public profiles keep display metadata (name, country, social levels), never
// coins, redeemable diamonds, KYC flags, debt or payout safety controls.
export const PRIVATE_WALLET_FIELDS = Object.freeze([
  "coins", "diamonds", "diamondsPending", "diamondsOnHold",
  "diamondsReserved", "walletDebtCoins", "walletFrozen", "payoutFrozen",
  "firstRechargeUsed", "payoutFreezeReason", "identityVerified",
  "purchasedCoins", "quizCoinsEarned", "withdrawableDiamonds", "walletBalance",
]);
const NON_NEGATIVE = Object.freeze([
  "coins", "diamonds", "diamondsPending", "diamondsOnHold",
  "diamondsReserved", "walletDebtCoins", "purchasedCoins",
  "quizCoinsEarned",
]);
// This server-only control must be approved AFTER backup, client/rules rollout
// verification and a zero-conflict migration. Setting economy_config.enabled
// alone never allows real-money operations.
export function requirePrivateWalletCutover(control) {
  if (!control || control.approved !== true ||
      control.completed !== true || control.schemaVersion !== 2) {
    throw Object.assign(
      new Error("Private wallet migration requires finance approval."),
      {status:503},
    );
  }
  return true;
}

export function privateWalletRef(userRef) {
  return userRef.collection("private_wallet").doc("summary");
}
export function containsLegacyWalletFields(profile) {
  return PRIVATE_WALLET_FIELDS.some(key =>
    Object.prototype.hasOwnProperty.call(profile || {}, key));
}
export function legacyWalletSnapshot(profile) {
  const output = {};
  for (const key of PRIVATE_WALLET_FIELDS) {
    if (Object.prototype.hasOwnProperty.call(profile || {}, key)) {
      output[key] = profile[key];
    }
  }
  for (const key of NON_NEGATIVE) {
    if (Object.prototype.hasOwnProperty.call(output, key) &&
        (!Number.isSafeInteger(output[key]) || output[key] < 0)) {
      throw new Error(`Invalid legacy wallet field: ${key}`);
    }
  }
  return {
    coins: 0, diamonds: 0, diamondsPending: 0, diamondsReserved: 0,
    walletDebtCoins: 0, walletFrozen: false, payoutFrozen: false,
    purchasedCoins: 0, firstRechargeUsed: false,
    ...output,
  };
}
export function assertMigrationConsistency(existingPrivate, legacyRoot) {
  if (!existingPrivate) return;
  for (const key of PRIVATE_WALLET_FIELDS) {
    if (Object.prototype.hasOwnProperty.call(legacyRoot || {}, key) &&
        // Values have already been normalized by validation before calling.
        existingPrivate[key] !== legacyRoot[key]) {
      throw new Error(`Private wallet and old profile conflict: ${key}`);
    }
  }
}
