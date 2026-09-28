import test from "node:test";
import assert from "node:assert/strict";
import {
  sanitizedPublicProfile, extractPrivateWallet,
  walletCopyMatches, publicCopyMatches,
} from "../src/wallet_privacy.js";

test("public profile projection cannot expose emails, full DOB, city or money", () => {
  const source = {
    uid: "owner", displayName: "Name", username: "handle",
    country: "SA", city: "Private city", birthDate: "1990-01-01",
    email: "private@example.com", coins: 1000, diamondsPending: 25,
    walletDebtCoins: 4, identityVerified: true,
  };
  assert.deepEqual(sanitizedPublicProfile("owner", source), {
    uid: "owner", displayName: "Name", username: "handle", country: "SA",
  });
  assert.deepEqual(extractPrivateWallet(source), {
    coins: 1000, diamondsPending: 25, walletDebtCoins: 4,
    identityVerified: true,
  });
});

test("broken legacy money stops the migration rather than resetting it", () => {
  assert.throws(() => extractPrivateWallet({coins: -2}), /Invalid legacy/);
  assert.throws(() => extractPrivateWallet({diamonds: 4.5}), /Invalid legacy/);
  assert.throws(() => extractPrivateWallet({walletDebtCoins: -1}), /Invalid legacy/);
});

test("new accounts may start with an empty private wallet", () => {
  assert.deepEqual(extractPrivateWallet({displayName: "New"}), {});
});

test("an existing wallet copy must match live money before cutover", () => {
  const source = {coins: 80, diamonds: 3, isVip: true};
  assert.equal(walletCopyMatches(source, {
    coins: 80, diamonds: 3, migrationVersion: 1,
  }), true);
  assert.equal(walletCopyMatches(source, {
    coins: 79, diamonds: 3, migrationVersion: 1,
  }), false);
  assert.equal(walletCopyMatches(source, {
    coins: 80, migrationVersion: 1,
  }), false);
});

test("a partial migration permits only a safe matching public copy", () => {
  const legacy = {
    displayName: "Name", country: "SA", coins: 50,
    birthDate: "2000-01-01", email: "private@example.com",
  };
  const safe = sanitizedPublicProfile("owner", legacy);
  assert.equal(publicCopyMatches("owner", legacy, {
    ...safe, migrationVersion: 1, snapshotAt: {toMillis: () => 123},
  }), true);
  assert.equal(publicCopyMatches("owner", legacy, {
    ...safe, coins: 50,
  }), false);
  assert.equal(publicCopyMatches("owner", legacy, {
    ...safe, birthDate: "2000-01-01",
  }), false);
  assert.equal(publicCopyMatches("owner", legacy, {uid: "owner"}), false);
});

test("unverified legacy VIP and verification flags cannot enter public projection", () => {
  const legacy = {
    displayName: "Owner", giftLevel: 7, isVip: true,
    isVerified: true, isPartner: true, travel: "Private",
    learningGoals: "Private", coins: 500, giftLevelPoints: 200,
  };
  const profile = sanitizedPublicProfile("owner", legacy);
  assert.deepEqual(profile, {
    uid: "owner", displayName: "Owner", giftLevel: 7,
  });
  assert.equal(extractPrivateWallet(legacy).giftLevelPoints, 200);
  assert.throws(() =>
    extractPrivateWallet({giftLevelPoints: -1}), /Invalid legacy/);
});
