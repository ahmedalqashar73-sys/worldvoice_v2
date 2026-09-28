import test from "node:test";
import assert from "node:assert/strict";
import {
  validateEconomy, giftQuote, coinCredit, exchangeQuote, withdrawalQuote,
  positiveBalance
} from "../src/economy_core.js";
const cfg = {
  enabled: true, coinsPerUsd: 100, receiverSharePercent: 50,
  diamondUsdValue: 0.01, withdrawalFeePercent: 5,
  minWithdrawalDiamonds: 200, holdDays: 7,
  giftLevelPointsPerCoin: 1, exchangeBonusPercent: 10,
  minExchangeDiamonds: 100, cardBonusPercent: 10,
  firstRechargeBonusPercent: 20
};
test("missing/malformed/disabled monetary config never silently defaults", () => {
  assert.throws(() => validateEconomy({}), /missing/);
  assert.throws(() => validateEconomy({...cfg, enabled: false}), /not enabled/);
  assert.throws(() => validateEconomy({...cfg, receiverSharePercent: 101}), /percent/);
});
test("gift quote computes recipient diamonds, USD and sender points from configuration", () => {
  assert.deepEqual(giftQuote(cfg, 100, 2), {
    coins: 200, diamonds: 100, receiverUsd: 1, giftLevelPoints: 200
  });
  assert.throws(() => giftQuote(cfg, -1, 2), /Invalid/);
});
test("first recharge and web card bonuses never change purchased face value", () => {
  assert.deepEqual(coinCredit(cfg, 500, {webCard:true,firstRecharge:true}), {
    coins:650,baseCoins:500,cardBonus:50,firstBonus:100
  });
  assert.equal(coinCredit(cfg, 500).coins, 500);
});
test("diamond exchange respects minimum and configurable percent", () => {
  assert.deepEqual(exchangeQuote(cfg, 100), {
    diamonds:100,baseCoins:100,bonusCoins:10,totalCoins:110
  });
  assert.throws(() => exchangeQuote(cfg, 99), /EXCHANGE_MIN/);
});
test("withdrawal quotes and stored balances validate before payout", () => {
  assert.deepEqual(withdrawalQuote(cfg, 200), {
    diamonds: 200,grossUsd:2,feeUsd:0.1,netUsd:1.9
  });
  assert.throws(() => positiveBalance(-1), /invalid/);
});
