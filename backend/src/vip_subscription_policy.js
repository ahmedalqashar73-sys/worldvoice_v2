/**
 * Only provider-verified active membership periods may grant VIP.
 * Values in these functions are supplied by Google/Apple API responses, never
 * by Flutter or Firestore client writes.
 */
export function googleVipPeriod(purchase, expectedSku, now = Date.now()) {
  const state = String(purchase?.subscriptionState || "");
  const allowed = new Set([
    "SUBSCRIPTION_STATE_ACTIVE",
    "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
    "SUBSCRIPTION_STATE_CANCELED",
  ]);
  if (!allowed.has(state)) return null;
  const expiry = (purchase?.lineItems || [])
    .filter(line => line?.productId === expectedSku)
    .map(line => Date.parse(line.expiryTime || ""))
    .filter(Number.isFinite)
    .reduce((a, b) => Math.max(a, b), 0);
  if (expiry <= now) return null;
  return {expiry, receiptId: String(purchase?.latestOrderId || "")};
}

export function appleVipPeriod(transaction, expectedSku, expectedBundle, now = Date.now()) {
  if (transaction?.productId !== expectedSku ||
      transaction?.bundleId !== expectedBundle ||
      transaction?.revocationDate != null) return null;
  const expiry = Number(transaction.expiresDate || 0);
  const root = String(transaction.originalTransactionId || "");
  if (!Number.isSafeInteger(expiry) || expiry <= now || !root) return null;
  return {expiry, receiptId: root};
}
