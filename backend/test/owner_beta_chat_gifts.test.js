import test from "node:test";
import assert from "node:assert/strict";
import {ownerBetaChatDebit} from "../src/owner_beta_chat_gifts.js";

test("owner beta gifts consume administrative coins only", () => {
  assert.deepEqual(ownerBetaChatDebit({
    coins: 12000, adminCoins: 10000, priceCoins: 500,
  }), {balanceAfter: 11500, adminAfter: 9500,
    paidCoinsSpent: 0, pendingDiamonds: 0});
});

test("owner beta gifting never spends paid coins or makes redeemable credit", () => {
  for (const input of [
    {coins: 1000, adminCoins: 0, priceCoins: 1},
    {coins: 100, adminCoins: 40, priceCoins: 50},
    {coins: 100, adminCoins: 101, priceCoins: 1},
    {coins: 100, adminCoins: 100, priceCoins: 1, frozen: true},
    {coins: 100, adminCoins: 100, priceCoins: 1, debtCoins: 1},
    {coins: -1, adminCoins: 0, priceCoins: 1},
    {coins: 10, adminCoins: 10, priceCoins: 0},
    {coins: 10.1, adminCoins: 10, priceCoins: 1},
  ]) {
    assert.throws(() => ownerBetaChatDebit(input));
  }
});
