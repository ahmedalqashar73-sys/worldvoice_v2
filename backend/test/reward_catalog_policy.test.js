import test from 'node:test';
import assert from 'node:assert/strict';
import {cycleRewards, DAY_MS} from '../src/engagement_policy.js';
test('new reward journey grants distinct existing 1, 3, 5 gifts', () => {
  const rewards = cycleRewards({}, 21000 * DAY_MS);
  assert.deepEqual(rewards.map(r => r.giftId), ['wv_gift_001', 'wv_gift_002', 'wv_gift_003']);
  assert.deepEqual(rewards.map(r => r.priceCoins), [1, 3, 5]);
  assert.deepEqual(rewards.map(r => r.quantity), [1, 1, 1]);
});
test('in-progress old cycle preserves promised gifts until next cycle', () => {
  const old = {startDay: 21000, claimedDays: 2};
  assert.deepEqual(cycleRewards(old, 21002 * DAY_MS).map(r => r.quantity), [1, 2, 3]);
  assert.deepEqual(cycleRewards(old, 21004 * DAY_MS).map(r => r.priceCoins), [1, 3, 5]);
  assert.deepEqual(cycleRewards({...old, rewardVersion: 2}, 21002 * DAY_MS).map(r => r.quantity), [1, 1, 1]);
});
