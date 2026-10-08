import test from "node:test";
import assert from "node:assert/strict";
import {approvedPayoutWindows, withdrawalQuote} from "../src/wallet_policy.js";

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
