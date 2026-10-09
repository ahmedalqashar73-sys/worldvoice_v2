import test from "node:test";
import assert from "node:assert/strict";
import {reversalDelta} from "../src/reversal_policy.js";

test("full refund reverses whole verified credit once", () => {
  assert.deepEqual(reversalDelta({
    creditedCoins: 550, priceCents: 1000, targetRefundCents: 1000,
  }), {totalDebit: 550, deltaCoins: 550, reversed: true});
  assert.deepEqual(reversalDelta({
    creditedCoins: 550, priceCents: 1000, targetRefundCents: 1000,
    alreadyDebitedCoins: 550,
  }), {totalDebit: 550, deltaCoins: 0, reversed: true});
});
test("cumulative partial refunds debit only new difference", () => {
  assert.deepEqual(reversalDelta({
    creditedCoins: 550, priceCents: 1000, targetRefundCents: 200,
  }).deltaCoins, 110);
  assert.deepEqual(reversalDelta({
    creditedCoins: 550, priceCents: 1000, targetRefundCents: 400,
    alreadyDebitedCoins: 110,
  }).deltaCoins, 110);
});
test("non-monotonic and forged amounts are rejected", () => {
  assert.throws(() => reversalDelta({
    creditedCoins: 500, priceCents: 1000, targetRefundCents: 1001,
  }));
  assert.throws(() => reversalDelta({
    creditedCoins: 500, priceCents: 1000, targetRefundCents: 300,
    alreadyDebitedCoins: 300,
  }));
});
