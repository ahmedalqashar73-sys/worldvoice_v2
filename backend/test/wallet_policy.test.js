import test from "node:test";
import assert from "node:assert/strict";
import {approvedPayoutWindows, withdrawalQuote, assertSameWithdrawalIntent, assertPayoutReviewAllowed} from "../src/wallet_policy.js";

// Synthetic test numbers, never published or relied on by the app/backend.
const policy = {
  minWithdrawalDiamonds: 100, diamondUsdValue: 0.02,
  withdrawalFeePercent: 5,
  withdrawalMethods: ["paypal", "payoneer", "bank", "local_wallet"],
  payoutWindows: [3, 16],
};
test("payout quote derives all amounts exclusively from policy", () => {
  assert.deepEqual(withdrawalQuote(policy, 1000, new Date("2026-09-20T00:00:00Z")), {
    diamonds: 1000, grossUsd: 20, feeUsd: 1, netUsd: 19,
    payoutWindow: "2026-10-03",
  });
});
test("payout windows require two distinct configured days", () => {
  assert.throws(() => approvedPayoutWindows({...policy, payoutWindows: [3, 3]}, new Date()));
  assert.throws(() => approvedPayoutWindows({...policy, payoutWindows: []}, new Date()));
  assert.equal(approvedPayoutWindows(policy, new Date("2026-09-02T00:00:00Z")),
    "2026-09-03");
});
test("minimum, invalid configuration and unavailable payout methods fail closed", () => {
  assert.throws(() => withdrawalQuote(policy, 10, new Date()));
  assert.throws(() => withdrawalQuote({...policy, withdrawalMethods: []}, 100, new Date()));
  assert.throws(() => withdrawalQuote({...policy, diamondUsdValue: 0}, 100, new Date()));
});

test("idempotent withdrawal retry requires identical payout destination", () => {
  const original = {
    userId: "member-1", diamonds: 400, method: "bank",
    payoutAccountToken: "payout_token_one_123",
  };
  const same = {
    uid: "member-1", diamonds: 400, method: "bank",
    payoutAccountToken: "payout_token_one_123",
  };
  assert.doesNotThrow(() => assertSameWithdrawalIntent(original, same));
  for (const change of [
    {uid: "member-2"},
    {diamonds: 500},
    {method: "paypal"},
    {payoutAccountToken: "payout_token_two_456"},
  ]) {
    assert.throws(
      () => assertSameWithdrawalIntent(original, {...same, ...change}),
      {status: 409},
    );
  }
});

test("payout review is re-gated against freezes, debt and KYC changes", () => {
  const verifiedOwner = {
    identityVerified: true, walletFrozen: false,
    payoutFrozen: false, walletDebtCoins: 0,
  };
  assert.doesNotThrow(() =>
    assertPayoutReviewAllowed(verifiedOwner, {frozen: false}));
  for (const change of [
    {walletFrozen: true}, {payoutFrozen: true},
    {walletDebtCoins: 2}, {walletDebtCoins: -1},
    {walletDebtCoins: NaN}, {identityVerified: false},
  ]) {
    assert.throws(
      () => assertPayoutReviewAllowed({...verifiedOwner, ...change}, {}),
      {status: 423},
    );
  }
  assert.throws(
    () => assertPayoutReviewAllowed(verifiedOwner, {frozen: true}),
    {status: 423},
  );
  assert.throws(
    () => assertPayoutReviewAllowed(null, {frozen: false}),
    {status: 423},
  );
});
