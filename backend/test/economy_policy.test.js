import test from "node:test";
import assert from "node:assert/strict";
import {requireLiveEconomy, calculateGiftSettlement} from "../src/economy_policy.js";

// Values in tests are synthetic fixtures, NOT published economy settings.
const fixture = {
  enabled: true, coinsPerUsd: 100, receiverSharePercent: 40,
  diamondUsdValue: 0.01, withdrawalFeePercent: 5,
  exchangeBonusPercent: 10, webCardBonusPercent: 10,
  giftLevelPointsPerCoin: 1, holdDays: 3,
  minWithdrawalDiamonds: 100, minExchangeDiamonds: 100,
};
test("economy stays locked without complete approved values", () => {
  assert.throws(() => requireLiveEconomy({enabled: false}));
  assert.throws(() => requireLiveEconomy({...fixture, diamondUsdValue: null}));
  assert.throws(() => requireLiveEconomy({...fixture, receiverSharePercent: 150}));
});
test("uses free gift inventory first and settles only paid portion", () => {
  const r = calculateGiftSettlement({
    config: fixture, priceCoins: 50, quantity: 3, freeGiftBalance: 2,
  });
  assert.deepEqual(r, {
    freeUnits: 2, chargedCoins: 50, giftLevelPoints: 50,
    pendingDiamonds: 20,
  });
});
test("all-free gifts produce no cashout liability", () => {
  const r = calculateGiftSettlement({
    config: fixture, priceCoins: 50, quantity: 2, freeGiftBalance: 3,
  });
  assert.equal(r.pendingDiamonds, 0);
  assert.equal(r.chargedCoins, 0);
  assert.equal(r.giftLevelPoints, 0);
});
test("invalid amount or overflow is rejected", () => {
  assert.throws(() => calculateGiftSettlement({
    config: fixture, priceCoins: -1, quantity: 1, freeGiftBalance: 0,
  }));
  assert.throws(() => calculateGiftSettlement({
    config: fixture, priceCoins: Number.MAX_SAFE_INTEGER,
    quantity: 2, freeGiftBalance: 0,
  }));
});
