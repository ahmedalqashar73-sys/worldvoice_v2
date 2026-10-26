// Pure reversal arithmetic for cumulative partial refunds and chargebacks.
// Uses the original server-issued credited amount, not client-supplied coins.
export function reversalDelta({
  creditedCoins, priceCents, targetRefundCents, alreadyDebitedCoins = 0,
}) {
  if (![creditedCoins, priceCents, targetRefundCents, alreadyDebitedCoins]
    .every(Number.isSafeInteger) || creditedCoins <= 0 || priceCents <= 0 ||
    targetRefundCents < 0 || targetRefundCents > priceCents ||
    alreadyDebitedCoins < 0 || alreadyDebitedCoins > creditedCoins) {
    throw Object.assign(new Error("Invalid payment reversal state."), {status: 409});
  }
  const totalDebit = Math.ceil(
    creditedCoins * targetRefundCents / priceCents,
  );
  if (!Number.isSafeInteger(totalDebit) ||
      totalDebit < alreadyDebitedCoins || totalDebit > creditedCoins) {
    throw Object.assign(new Error("Non-monotonic payment reversal."), {status: 409});
  }
  return {totalDebit, deltaCoins: totalDebit - alreadyDebitedCoins,
    reversed: targetRefundCents === priceCents};
}
