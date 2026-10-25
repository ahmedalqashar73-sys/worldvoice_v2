import test from 'node:test';
import assert from 'node:assert/strict';
import {
  worldVoiceChatBubbles, vipChatBubbles, builtInChatBubble,
  chatBubbleInventoryId, resultingBubbleExpiry, vipBubbleAllowed,
} from '../src/chat_bubble_policy.js';

test('15 distinct designs; four in each paid tier and three VIP', () => {
  assert.equal(Object.keys(worldVoiceChatBubbles).length, 12);
  assert.equal(vipChatBubbles.length, 3);
  assert.equal(new Set([...Object.keys(worldVoiceChatBubbles), ...vipChatBubbles]).size, 15);
});

test('canonical approved prices and durations', () => {
  const tiers = [
    ['emerald', [25, 80, 600]],
    ['sakura', [60, 180, 1500]],
    ['dragon', [120, 360, 3000]],
  ];
  for (const [name, prices] of tiers) {
    for (const [i, days] of ['7', '30', 'permanent'].entries()) {
      const item = builtInChatBubble('bubble__' + name + '__' + days);
      assert.equal(item.priceCoins, prices[i]);
      assert.equal(item.durationDays, days === 'permanent' ? null : Number(days));
      assert.equal(item.bubbleId, name);
    }
  }
  for (const invalid of [
    'bubble__vip_gold__7', 'bubble__dragon__365', 'bubble__other__7',
    'frame__emerald__7', 'bubble__rose__-30',
  ]) assert.equal(builtInChatBubble(invalid), null);
  assert.equal(chatBubbleInventoryId('emerald'), 'bubble__emerald');
  assert.equal(chatBubbleInventoryId('vip_gold'), null);
});

test('repeat gift extends remaining time; expired grant begins at arrival', () => {
  const now = Date.UTC(2026, 9, 25);
  const later = now + 12 * 86400000;
  const active = resultingBubbleExpiry({
    existing: {quantity: 1, expiresAt: {toMillis: () => later}},
    durationDays: 30, now,
  });
  assert.equal(active.expiresMillis, now + 42 * 86400000);
  const expired = resultingBubbleExpiry({
    existing: {quantity: 1, expiresAt: {toMillis: () => now - 1000}},
    durationDays: 7, now,
  });
  assert.equal(expired.expiresMillis, now + 7 * 86400000);
  const permanent = resultingBubbleExpiry({
    existing: {quantity: 1, expiresAt: null}, durationDays: 30, now,
  });
  assert.equal(permanent.alreadyPermanent, true);
  assert.equal(permanent.expiresMillis, null);
});

test('VIP cosmetics require active verified membership', () => {
  const now = Date.now();
  assert.equal(vipBubbleAllowed({isVip: true}, now), true);
  assert.equal(vipBubbleAllowed({isVip: false}, now), false);
  assert.equal(vipBubbleAllowed({isVip: true,
    vipExpiresAt: {toMillis: () => now - 1}}, now), false);
  assert.equal(vipBubbleAllowed({isVip: true,
    vipExpiresAt: {toMillis: () => now + 10000}}, now), true);
});
