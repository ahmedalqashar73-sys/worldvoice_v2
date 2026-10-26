import {isActiveVipProfile} from './vip_feature_policy.js';
export const vipPlans = Object.freeze(['monthly', 'quarterly', 'half_year', 'annual', 'lifetime']);
export const extraBadges = Object.freeze({aurora: 120, sakura: 120, celestial: 180});
export function giftThreshold(level) { return 5 * level * (level + 3); }
export function giftProgress(wallet = {}) {
  const raw = wallet.giftLevelCoins ?? wallet.giftSentPoints;
  const coins = Number.isSafeInteger(raw) && raw >= 0 ? raw : 0;
  let level = Math.max(0, Math.min(50, Number.isSafeInteger(wallet.giftLevel) ? wallet.giftLevel : 0));
  for (let i = level + 1; i <= 50 && coins >= giftThreshold(i); i++) level = i;
  // Preserve earned levels during migration; new spending advances from that floor.
  const points = Math.max(coins, giftThreshold(level));
  return {level, points, next: level === 50 ? null : giftThreshold(level + 1),
    remaining: level === 50 ? 0 : giftThreshold(level + 1) - points};
}
export function automaticVipBadge(profile, now = Date.now(), entitlement = {}) {
  if (!isActiveVipProfile(profile, now)) return null;
  const plan = entitlement.plan;
  return vipPlans.includes(plan) ? plan : 'monthly';
}
export function visibleVipBadge(profile, state = {}, now = Date.now()) {
  const automatic = automaticVipBadge(profile, now, state);
  if (!automatic) return null;
  return Object.hasOwn(extraBadges, state.selected) && state.owned?.includes(state.selected)
    ? state.selected : automatic;
}
