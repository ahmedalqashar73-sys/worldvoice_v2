import test from "node:test";
import assert from "node:assert/strict";
import {OWNER_MONTHLY_COINS, ownerMonthInRiyadh, splitOwnerCoinSpend,
  diamondsForPaidCoins, cosmeticGiftPrice} from "../src/owner_coin_policy.js";

test("owner monthly coin grant is fixed, and Riyadh period is calendar-local", () => {
  assert.equal(OWNER_MONTHLY_COINS, 10_000);
  assert.equal(ownerMonthInRiyadh(new Date("2026-10-31T21:00:00Z")), "2026-11");
  assert.equal(ownerMonthInRiyadh(new Date("2026-11-30T20:59:59Z")), "2026-11");
  assert.equal(ownerMonthInRiyadh(new Date("2026-11-30T21:00:00Z")), "2026-12");
});

test("admin balance spends first, and mixed gifting uses paid coin remainder", () => {
  assert.deepEqual(splitOwnerCoinSpend({coins: 1200, adminCoins: 200, amount: 500}), {
    adminSpent: 200, paidSpent: 300, remainingAdminCoins: 0, remainingCoins: 700,
  });
  assert.deepEqual(splitOwnerCoinSpend({coins: 10000, adminCoins: 10000, amount: 1000}), {
    adminSpent: 1000, paidSpent: 0, remainingAdminCoins: 9000, remainingCoins: 9000,
  });
  assert.throws(() => splitOwnerCoinSpend({coins: 10, adminCoins: 20, amount: 5}));
  assert.throws(() => splitOwnerCoinSpend({coins: 10, adminCoins: 0, amount: 11}));
});

test("free owner coins never create payable recipient diamonds", () => {
  const config = {coinsPerUsd: 100, receiverSharePercent: 50, diamondUsdValue: 0.01};
  assert.equal(diamondsForPaidCoins({config, paidCoins: 0}), 0);
  assert.equal(diamondsForPaidCoins({config, paidCoins: 300}), 150);
});

test("existing permanent cosmetic prices remain unchanged", () => {
  assert.deepEqual([3, 7, 10, 15, 30, null].map(d => cosmeticGiftPrice(150, d)),
    [25, 40, 55, 70, 90, 150]);
  assert.equal(cosmeticGiftPrice(520, 7), 130);
  assert.throws(() => cosmeticGiftPrice(150, 31));
  assert.throws(() => cosmeticGiftPrice(150, "7"));
});
