/**
 * Single owner-only balance location. Legacy users/{uid} remains a profile
 * document during the staged client migration; NEVER debit its balance fields.
 * This helper fails closed until the non-destructive wallet migration runs.
 */
export function privateWalletRef(userRef) {
  if (!userRef || userRef.parent?.id !== "users") {
    throw new TypeError("Expected a users/{uid} document reference.");
  }
  return userRef.collection("private").doc("wallet");
}

export function requirePrivateWallet(snapshot) {
  if (!snapshot?.exists) {
    throw Object.assign(new Error(
      "Private wallet migration is required before monetary operations."),
    {status: 503});
  }
  const data = snapshot.data() || {};
  for (const field of ["coins", "diamonds", "diamondsPending",
    "diamondsReserved", "walletDebtCoins"]) {
    const value = data[field];
    if (value != null &&
        (!Number.isSafeInteger(value) || value < 0)) {
      throw Object.assign(new Error("Wallet balance requires reconciliation."),
        {status: 503});
    }
  }
  return data;
}
