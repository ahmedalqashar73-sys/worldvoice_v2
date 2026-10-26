// UTC midnight is 03:00 Saudi Arabia. Device time never enters this policy.
export const DAY_MS = 86400000;
export const CYCLE_GIFT_ID = 'wv_gift_001';
export function cycleView(state = {}, now = Date.now()) {
  const today = Math.floor(now / DAY_MS), start = state.startDay;
  const claimed = state.claimedDays ?? 0;
  if (Number.isInteger(start)) {
    const offset = today - start;
    if (offset < 0) throw Object.assign(new Error('Invalid cycle clock.'), {status: 409});
    if (claimed === 3 && offset <= 3) return {startDay: start,
      day: Math.min(offset + 1, 4), claimedDays: 3,
      phase: offset === 3 ? 'rest' : 'claimed', canClaim: false,
      nextAtMs: (start + 4) * DAY_MS};
    if (offset < 3 && claimed >= offset) return {startDay: start,
      day: offset + 1, claimedDays: claimed,
      phase: claimed > offset ? 'claimed' : 'ready', canClaim: claimed === offset,
      nextAtMs: (today + 1) * DAY_MS};
  }
  return {startDay: today, day: 1, claimedDays: 0, phase: 'ready',
    canClaim: true, nextAtMs: (today + 1) * DAY_MS};
}
export function cycleEvidence(state, now) {
  const view = cycleView(state, now);
  return view.startDay === state?.startDay && view.day <= 3
    ? {activeMs: state.activeMs ?? 0, hostedFive: state.hostedFive === true}
    : {activeMs: 0, hostedFive: false};
}
export function creativeAward(state, now) {
  if (!(state.claimedDays === 3 && state.activeMs >= 3600000 &&
    state.hostedFive === true && state.awardedCycle !== state.startDay)) return state;
  return {...state, awardedCycle: state.startDay,
    creativeCycles: (state.creativeCycles ?? 0) + 1,
    creativeAwardedAtMs: state.creativeAwardedAtMs ?? now};
}
// Global clock caps simultaneous rooms so verified time cannot be multiplied.
export function addCyclePresence(state, verifiedDelta, now) {
  const view = cycleView(state, now);
  if (state.startDay !== view.startDay || view.day > 3) return state;
  const credit = Math.max(0, Math.min(verifiedDelta,
    state.lastPresenceMs == null ? 0 : now - state.lastPresenceMs, 90000));
  return creativeAward({...state, lastPresenceMs: now,
    activeMs: Math.min(3600000, (state.activeMs ?? 0) + credit)}, now);
}
