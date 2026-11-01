import test from "node:test";
import assert from "node:assert/strict";
import {OWNER_MONTHLY_COINS, ownerMonthInRiyadh, splitOwnerCoinSpend,
  diamondsForPaidCoins, cosmeticGiftPrice,
  refundablePaidCoinDebit, isVerifiedOwnerIdentity,
  ownerWalletFromLegacyProfile, matchesOwnerGoogleProof} from "../src/owner_coin_policy.js";

test("owner monthly coin grant is fixed, and Riyadh period is calendar-local", () => {
  assert.equal(OWNER_MONTHLY_COINS, 10_000);
  assert.equal(ownerMonthInRiyadh(new Date("2026-10-31T21:00:00Z")), "2026-11");
  assert.equal(ownerMonthInRiyadh(new Date("2026-11-30T20:59:59Z")), "2026-11");
  assert.equal(ownerMonthInRiyadh(new Date("2026-11-30T21:00:00Z")), "2026-12");
});

test("admin balance spends first, and mixed gifting uses paid coin remainder", () => {
  assert.deepEqual(splitOwnerCoinSpend({coins: 1200, adminCoins: 200, amount: 500}), {
    adminSpent: 200, paidSpent: 300, remainingAdminCoins: 0, remainingCoins: 700,
  });
  assert.deepEqual(splitOwnerCoinSpend({coins: 10000, adminCoins: 10000, amount: 1000}), {
    adminSpent: 1000, paidSpent: 0, remainingAdminCoins: 9000, remainingCoins: 9000,
  });
  assert.throws(() => splitOwnerCoinSpend({coins: 10, adminCoins: 20, amount: 5}));
  assert.throws(() => splitOwnerCoinSpend({coins: 10, adminCoins: 0, amount: 11}));
});

test("free owner coins never create payable recipient diamonds", () => {
  const config = {coinsPerUsd: 100, receiverSharePercent: 50, diamondUsdValue: 0.01};
  assert.equal(diamondsForPaidCoins({config, paidCoins: 0}), 0);
  assert.equal(diamondsForPaidCoins({config, paidCoins: 300}), 150);
});

test("existing permanent cosmetic prices remain unchanged", () => {
  assert.deepEqual([3, 7, 10, 15, 30, null].map(d => cosmeticGiftPrice(150, d)),
    [25, 40, 55, 70, 90, 150]);
  assert.equal(cosmeticGiftPrice(520, 7), 130);
  assert.throws(() => cosmeticGiftPrice(150, 31));
  assert.throws(() => cosmeticGiftPrice(150, "7"));
});

test("purchase refunds never debit granted owner coins", () => {
  assert.deepEqual(refundablePaidCoinDebit({
    coins: 1200, adminCoins: 1000, refundCoins: 500,
  }), {availableDebit: 200, debtCoins: 300});
  assert.deepEqual(refundablePaidCoinDebit({
    coins: 1000, adminCoins: 1000, refundCoins: 100,
  }), {availableDebit: 0, debtCoins: 100});
  assert.deepEqual(refundablePaidCoinDebit({
    coins: 500, adminCoins: 0, refundCoins: 200,
  }), {availableDebit: 200, debtCoins: 0});
  assert.throws(() => refundablePaidCoinDebit({
    coins: 50, adminCoins: 55, refundCoins: 1,
  }));
});

test("owner identity accepts only verified signed credentials", () => {
  const allowed = new Map([["legacy@example.com", {role: "super_admin"}]]);
  const signed = {
    uid: "owner_uid", email: "owner@example.com", email_verified: true,
    admin: true, economyAdmin: true, worldVoiceAdmin: true,
  };
  assert.equal(isVerifiedOwnerIdentity(signed, allowed), true);
  assert.equal(isVerifiedOwnerIdentity({
    uid: "legacy_uid", email: "LEGACY@example.com", email_verified: true,
  }, allowed), true);
  assert.equal(isVerifiedOwnerIdentity({...signed, email_verified: false}, allowed), false);
  assert.equal(isVerifiedOwnerIdentity({...signed, worldVoiceAdmin: false}, allowed), false);
  assert.equal(isVerifiedOwnerIdentity({
    email: "member@example.com", email_verified: true, isAdmin: true,
  }, allowed), false);
  assert.equal(isVerifiedOwnerIdentity({
    uid: "trusted_uid", email: "trusted@example.com", email_verified: true,
  }, allowed, {
    active: true, role: "super_admin", uid: "trusted_uid",
    email: "TRUSTED@example.com",
  }), true);
  assert.equal(isVerifiedOwnerIdentity({
    uid: "trusted_uid", email: "trusted@example.com", email_verified: true,
  }, allowed, {
    active: true, role: "super_admin", uid: "other_uid",
    email: "trusted@example.com",
  }), false);
  assert.equal(isVerifiedOwnerIdentity({
    uid: "trusted_uid", email: "trusted@example.com", email_verified: true,
  }, allowed, {
    active: true, role: "super_admin", uid: "trusted_uid",
    email: "different@example.com",
  }), false);
  // A protected admin record is not a substitute for recent Google proof
  // when the Firebase email is unverified.
  assert.equal(isVerifiedOwnerIdentity({
    uid: "trusted_uid", email: "trusted@example.com", email_verified: false,
  }, allowed, {
    active: true, role: "super_admin", uid: "trusted_uid",
    email: "TRUSTED@example.com",
  }), false);
  for (const invalid of [
    {active: false, role: "super_admin", uid: "trusted_uid", email: "trusted@example.com"},
    {active: true, role: "super_admin", uid: "other_uid", email: "trusted@example.com"},
    {active: true, role: "super_admin", uid: "trusted_uid", email: "different@example.com"},
    {active: true, role: "admin", uid: "trusted_uid", email: "trusted@example.com"},
  ]) {
    assert.equal(isVerifiedOwnerIdentity({
      uid: "trusted_uid", email: "trusted@example.com", email_verified: false,
    }, allowed, invalid), false);
  }
  assert.equal(isVerifiedOwnerIdentity({
    uid: "trusted_uid", email: "trusted@example.com", email_verified: false,
    isAdmin: true,
  }, allowed), false);
  assert.equal(isVerifiedOwnerIdentity(null, allowed), false);
});

test("owner wallet bootstrap preserves validated legacy money and begins admin coins at zero", () => {
  assert.deepEqual(ownerWalletFromLegacyProfile({}), {
    coins: 0, diamonds: 0, diamondsPending: 0,
    diamondsReserved: 0, walletDebtCoins: 0, adminCoins: 0,
  });
  const wallet = ownerWalletFromLegacyProfile({
    coins: 120, diamonds: 3, walletDebtCoins: 0,
    purchasedCoins: 120, walletFrozen: false, adminCoins: 500,
  });
  assert.equal(wallet.coins, 120);
  assert.equal(wallet.diamonds, 3);
  assert.equal(wallet.purchasedCoins, 120);
  assert.equal(wallet.adminCoins, 0);
  assert.throws(() => ownerWalletFromLegacyProfile({coins: -1}));
  assert.throws(() => ownerWalletFromLegacyProfile({walletBalance: 900}));
  assert.throws(() => ownerWalletFromLegacyProfile({withdrawableDiamonds: 4}));
});

test("Google ownership recovery needs verified Google email and exact protected UID", () => {
  const ownerEmail = "legacy@example.com";
  const firebaseUser = {
    uid: "legacyUid", email: "legacy@example.com", disabled: false,
  };
  const ownerRecord = {
    uid: "legacyUid", email: "LEGACY@example.com",
    role: "super_admin", active: true,
  };
  const googleProof = {
    email: "legacy@example.com", email_verified: true,
  };
  const args = {firebaseUser, ownerRecord, googleProof, ownerEmail};
  assert.equal(matchesOwnerGoogleProof(args), true);
  assert.equal(matchesOwnerGoogleProof({
    ...args, googleProof: {...googleProof, email_verified: false},
  }), false);
  assert.equal(matchesOwnerGoogleProof({
    ...args, googleProof: {...googleProof, email: "other@example.com"},
  }), false);
  assert.equal(matchesOwnerGoogleProof({
    ...args, firebaseUser: {...firebaseUser, uid: "differentUid"},
  }), false);
  assert.equal(matchesOwnerGoogleProof({
    ...args, firebaseUser: {...firebaseUser, disabled: true},
  }), false);
  assert.equal(matchesOwnerGoogleProof({
    ...args, ownerRecord: {...ownerRecord, active: false},
  }), false);
  assert.equal(matchesOwnerGoogleProof({
    ...args, ownerRecord: {...ownerRecord, role: "moderator"},
  }), false);
});
