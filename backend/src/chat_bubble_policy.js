// Server-owned price list. Never accept a price or entitlement duration from Flutter.
export const worldVoiceChatBubbles = Object.freeze({
  emerald: 'classic', ocean: 'classic', rose: 'classic', moonlight: 'classic',
  sakura: 'premium', galaxy: 'premium', butterfly: 'premium', cat: 'premium',
  dragon: 'royal', phoenix: 'royal', socotra: 'royal', crown: 'royal',
});
export const vipChatBubbles = Object.freeze(['vip_gold', 'vip_galaxy', 'vip_sakura']);
const prices = Object.freeze({
  classic: Object.freeze({'7': 25, '30': 80, permanent: 600}),
  premium: Object.freeze({'7': 60, '30': 180, permanent: 1500}),
  royal: Object.freeze({'7': 120, '30': 360, permanent: 3000}),
});

export function builtInChatBubble(itemId) {
  const match = /^bubble__([a-z_]{2,30})__(7|30|permanent)$/.exec(itemId);
  if (!match) return null;
  const [, design, duration] = match;
  const tier = worldVoiceChatBubbles[design];
  if (!tier) return null;
  return {
    active: true,
    type: 'bubble',
    bubbleId: design,
    priceCoins: prices[tier][duration],
    durationDays: duration === 'permanent' ? null : Number(duration),
    requiredGiftLevel: 0,
    name: design,
  };
}

export function chatBubbleInventoryId(design) {
  if (!Object.hasOwn(worldVoiceChatBubbles, design)) return null;
  return 'bubble__' + design;
}

// Prices are fixed, gifts begin on arrival and extend unexpired ownership.
// An existing permanent grant is never reduced or charged again.
export function resultingBubbleExpiry({existing, durationDays, now}) {
  if (existing?.quantity > 0 && existing?.expiresAt === null) {
    return {alreadyPermanent: true, expiresMillis: null};
  }
  if (durationDays === null) return {alreadyPermanent: false, expiresMillis: null};
  const old = existing?.expiresAt?.toMillis?.() ?? 0;
  const base = Math.max(now, old);
  return {
    alreadyPermanent: false,
    expiresMillis: base + durationDays * 86400000,
  };
}

export function vipBubbleAllowed(profile, now) {
  if (profile?.isVip !== true) return false;
  const expiry = profile.vipExpiresAt;
  if (expiry == null) return true;
  const millis = expiry?.toMillis?.() ??
    (expiry instanceof Date ? expiry.getTime() : NaN);
  return Number.isFinite(millis) && millis > now;
}
