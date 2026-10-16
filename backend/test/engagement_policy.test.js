import test from 'node:test';
import assert from 'node:assert/strict';
import {DAY_MS, cycleView, cycleEvidence, creativeAward, addCyclePresence} from '../src/engagement_policy.js';
const startDay = 20000, now = startDay * DAY_MS;
test('three claims, mandatory rest and next cycle at server day boundary', () => {
  assert.equal(cycleView({}, now).day, 1);
  let state = {startDay, claimedDays: 1};
  assert.equal(cycleView(state, now).canClaim, false);
  assert.equal(cycleView(state, now + DAY_MS - 1).canClaim, false);
  assert.equal(cycleView(state, now + DAY_MS).day, 2);
  state.claimedDays = 2;
  assert.equal(cycleView(state, now + 2 * DAY_MS).day, 3);
  state.claimedDays = 3;
  assert.equal(cycleView(state, now + 3 * DAY_MS).phase, 'rest');
  assert.equal(cycleView(state, now + 4 * DAY_MS).day, 1);
});
test('missed day resets evidence while earned achievements survive', () => {
  const state = {startDay, claimedDays: 1, activeMs: 90000, hostedFive: true};
  assert.equal(cycleView(state, now + 2 * DAY_MS).startDay, startDay + 2);
  assert.deepEqual(cycleEvidence(state, now + 2 * DAY_MS), {activeMs: 0, hostedFive: false});
});
test('creative badge needs all evidence and counts each cycle once', () => {
  const state = {startDay, claimedDays: 3, activeMs: 3600000, hostedFive: true};
  const award = creativeAward(state, now);
  assert.equal(award.creativeCycles, 1);
  assert.equal(creativeAward(award, now + 1).creativeCycles, 1);
  assert.equal(creativeAward({...state, hostedFive: false}, now).creativeCycles, undefined);
  assert.equal(creativeAward({...state, activeMs: 3599999}, now).creativeCycles, undefined);
});
test('parallel rooms do not multiply attendance; rest cannot earn progress', () => {
  const state = {startDay, claimedDays: 1, lastPresenceMs: now, activeMs: 0};
  const first = addCyclePresence(state, 30000, now + 30000);
  assert.equal(first.activeMs, 30000);
  assert.equal(addCyclePresence(first, 30000, now + 30000).activeMs, 30000);
  const rest = {...first, claimedDays: 3};
  assert.deepEqual(addCyclePresence(rest, 30000, now + 3 * DAY_MS), rest);
});
