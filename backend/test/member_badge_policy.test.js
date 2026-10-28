import test from 'node:test';
import assert from 'node:assert/strict';
import {giftProgress, giftThreshold, automaticVipBadge, visibleVipBadge, vipPlans} from '../src/member_badge_policy.js';
test('all 50 levels charge 20, 30, ... 510 extra coins', () => {
  let sum = 0;
  for (let level=1; level<=50; level++) {
    sum += 10*(level+1);
    assert.equal(giftThreshold(level), sum);
    assert.equal(giftProgress({giftSentPoints:sum-1}).level, level-1);
    assert.equal(giftProgress({giftSentPoints:sum}).level, level);
  }
  assert.equal(sum,13250);
  assert.equal(giftProgress({giftSentPoints:999999}).next,null);
});
test('legacy levels are retained; unspent coins never earn levels', () => {
  assert.equal(giftProgress({coins:100000}).level,0);
  assert.equal(giftProgress({giftLevel:20}).level,20);
  assert.equal(giftProgress({giftSentPoints:-1}).level,0);
});
test('five automatic badges require active VIP; cosmetics do not grant VIP', () => {
  for (const plan of vipPlans) assert.equal(automaticVipBadge({isVip:true},Date.now(),{plan}),plan);
  assert.equal(automaticVipBadge({isVip:false},Date.now(),{plan:'lifetime'}),null);
  assert.equal(automaticVipBadge({isVip:true,vipPlanId:'lifetime'}),'monthly');
  assert.equal(visibleVipBadge({isVip:true,vipExpiresAt:new Date(0)}, {owned:['sakura'],selected:'sakura'}),null);
  assert.equal(visibleVipBadge({isVip:true}, {owned:[],selected:'sakura'}),'monthly');
  assert.equal(visibleVipBadge({isVip:true}, {owned:['sakura'],selected:'sakura'}),'sakura');
});
