import {extractLegacyWallet} from "./profile_projection.js";

// Server-only rules for the WorldVoice owner's non-withdrawable monthly coins.
// The beta enrollment tool issues these three claims via Firebase Admin SDK.
// Never rely on client-writable profile flags for monetary authority.
export function isVerifiedOwnerIdentity(token, allowlistedAccounts,
  trustedAdmin = null) {
  const email = String(token?.email || "").trim().toLowerCase();
  if (!email || !token?.uid) return false;
  // A document written by Admin SDK, not a client-visible profile flag,
  // binds the authenticated Firebase UID to the same email and active role.
  // It remains valid when legacy Auth emailVerified metadata was never set.
  const verifiedRecord = trustedAdmin?.active === true &&
    trustedAdmin?.role === "super_admin" &&
    trustedAdmin.uid === token.uid &&
    String(trustedAdmin.email || "").trim().toLowerCase() === email;
  if (verifiedRecord) return true;
  // Without that stronger server-owned record, both the legacy email
  // allowlist and signed custom-claim route still require verified email.
  if (token.email_verified !== true) return false;
  return allowlistedAccounts?.get(email)?.role === "super_admin" ||
    (token.admin === true && token.economyAdmin === true &&
      token.worldVoiceAdmin === true);
}

/**
 * Separate Google OAuth proof for a *currently authenticated* legacy owner.
 * Google ID-token signature/audience/expiry are verified by OAuth2Client
 * before this pure predicate is called. Never accept a client-supplied email
 * alone, a profile isAdmin flag, or a user-supplied Firebase UID.
 */
export function matchesOwnerGoogleProof({firebaseUser, ownerRecord, googleProof,
  ownerEmail}) {
  const approved = String(ownerEmail || "").trim().toLowerCase();
  const email = String(firebaseUser?.email || "").trim().toLowerCase();
  const googleEmail = String(googleProof?.email || "").trim().toLowerCase();
  const googleVerified = googleProof?.email_verified === true ||
    googleProof?.email_verified === "true";
  return approved.length > 0 &&
    firebaseUser?.uid && firebaseUser?.disabled !== true &&
    email === approved && googleEmail === approved && googleVerified &&
    ownerRecord?.uid === firebaseUser.uid &&
    String(ownerRecord?.email || "").trim().toLowerCase() === approved &&
    ownerRecord?.role === "super_admin" && ownerRecord?.active === true;
}

export const OWNER_MONTHLY_COINS = 10_000;

// Only the verified owner can reach this bootstrap. Copy validated legacy
// balances on first migration; refuse to guess ambiguous financial fields.
export function ownerWalletFromLegacyProfile(profile) {
  const old = extractLegacyWallet(profile);
  if ((old.walletBalance ?? 0) > 0 && old.coins == null) {
    throw Object.assign(new Error("Legacy coin balance needs reconciliation."),
      {status: 409});
  }
  if ((old.withdrawableDiamonds ?? 0) > 0 && old.diamonds == null) {
    throw Object.assign(new Error("Legacy diamond balance needs reconciliation."),
      {status: 409});
  }
  return {
    ...old,
    coins: old.coins ?? 0,
    diamonds: old.diamonds ?? 0,
    diamondsPending: old.diamondsPending ?? 0,
    diamondsReserved: old.diamondsReserved ?? 0,
    walletDebtCoins: old.walletDebtCoins ?? 0,
    adminCoins: 0,
  };
}

export function ownerMonthInRiyadh(date = new Date()) {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Asia/Riyadh", year: "numeric", month: "2-digit",
  }).formatToParts(date);
  const year = parts.find(part => part.type === "year")?.value;
  const month = parts.find(part => part.type === "month")?.value;
  if (!/^\d{4}$/.test(year || "") || !/^\d{2}$/.test(month || "")) {
    throw new Error("Cannot determine owner grant month.");
  }
  return `${year}-${month}`;
}

export function splitOwnerCoinSpend({coins, adminCoins = 0, amount}) {
  if (![coins, adminCoins, amount].every(Number.isSafeInteger) ||
      coins < 0 || adminCoins < 0 || adminCoins > coins ||
      amount < 0 || amount > coins) {
    throw Object.assign(new Error("Invalid coin balance or purchase amount."), {status: 409});
  }
  const adminSpent = Math.min(adminCoins, amount);
  return {
    adminSpent, paidSpent: amount - adminSpent,
    remainingAdminCoins: adminCoins - adminSpent,
    remainingCoins: coins - amount,
  };
}

export function diamondsForPaidCoins({config, paidCoins}) {
  if (!Number.isSafeInteger(paidCoins) || paidCoins < 0 ||
      !Number.isFinite(config?.coinsPerUsd) || config.coinsPerUsd <= 0 ||
      !Number.isFinite(config?.diamondUsdValue) || config.diamondUsdValue <= 0 ||
      !Number.isFinite(config?.receiverSharePercent) ||
      config.receiverSharePercent < 0 || config.receiverSharePercent > 100) {
    throw Object.assign(new Error("Invalid paid coin settlement."), {status: 503});
  }
  const result = Math.floor(
    paidCoins / config.coinsPerUsd *
      (config.receiverSharePercent / 100) / config.diamondUsdValue);
  if (!Number.isSafeInteger(result) || result < 0) {
    throw Object.assign(new Error("Invalid recipient diamond amount."), {status: 400});
  }
  return result;
}

// Price percentages apply to the existing permanent prices, rounded up to 5 coins.
const durationRates = new Map([[3, 0.15], [7, 0.25], [10, 0.35],
  [15, 0.45], [30, 0.60], [null, 1]]);
export function cosmeticGiftPrice(permanentCoins, durationDays) {
  if (!Number.isSafeInteger(permanentCoins) || permanentCoins <= 0 ||
      !durationRates.has(durationDays)) {
    throw Object.assign(new Error("Unsupported cosmetic gift duration."), {status: 400});
  }
  return Math.ceil(permanentCoins * durationRates.get(durationDays) / 5) * 5;
}

// Refunds of store-verified coins cannot confiscate promotional owner coins.
// Insufficient paid balance becomes a reviewed wallet debt, not admin spending.
export function refundablePaidCoinDebit({coins, adminCoins = 0, refundCoins}) {
  if (![coins, adminCoins, refundCoins].every(Number.isSafeInteger) ||
      coins < 0 || adminCoins < 0 || adminCoins > coins ||
      refundCoins < 0) {
    throw Object.assign(new Error("Wallet refund requires reconciliation."),
      {status: 409});
  }
  const availableDebit = Math.min(coins - adminCoins, refundCoins);
  return {availableDebit, debtCoins: refundCoins - availableDebit};
}
