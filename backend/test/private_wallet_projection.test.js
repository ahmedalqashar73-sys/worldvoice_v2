import test from "node:test";
import assert from "node:assert/strict";
import {
  PRIVATE_WALLET_FIELDS, PUBLIC_PROFILE_FIELDS,
  projectPrivateWallet, projectPublicProfile, canBootstrapZeroWallet,
} from "../src/private_wallet_projection.js";

test("only approved public fields leave a legacy user document", () => {
  const legacy = {
    uid: "u1", displayName: "Learner", countryCode: "YE",
    nativeLanguageCode: "ar", bio: "Hello",
    coins: 200, diamonds: 18, diamondsPending: 4,
    walletDebtCoins: 3, walletFrozen: true, payoutFrozen: true,
    firstRechargeUsed: true, identityVerified: true,
    email: "private@example.com", phoneNumber: "+10000000000",
    city: "A private city", dateOfBirth: "2000-01-01",
    stripeCustomerId: "cus_secret", bankingDetails: {account: "secret"},
    lastKnownLocation: {latitude: 0, longitude: 0},
  };
  const pub = projectPublicProfile("u1", legacy);
  assert.deepEqual(pub, {
    uid: "u1", displayName: "Learner", countryCode: "YE",
    nativeLanguageCode: "ar", bio: "Hello",
  });
  assert.ok(PRIVATE_WALLET_FIELDS.every(field => !(field in pub)));
  assert.ok(PUBLIC_PROFILE_FIELDS.every(field => field !== "email"));
});

test("private wallet extraction preserves prior balances without crediting extras", () => {
  const result = projectPrivateWallet({
    coins: 502, diamonds: 23, diamondsPending: 11,
    purchasedCoins: 500, walletDebtCoins: 0,
    walletFrozen: true, email: "private@example.com",
  });
  assert.deepEqual(result, {
    coins: 502, diamonds: 23, diamondsPending: 11,
    purchasedCoins: 500, walletDebtCoins: 0, walletFrozen: true,
  });
});

test("missing legacy wallet is valid and never invents money", () => {
  assert.deepEqual(projectPrivateWallet({displayName: "New user"}), {});
});

test("negative and malformed balances fail closed", () => {
  for (const value of [-1, 1.5, Infinity, "42", NaN]) {
    assert.throws(
      () => projectPrivateWallet({coins: value}),
      /Invalid legacy wallet field/,
    );
  }
  assert.throws(
    () => projectPrivateWallet({walletFrozen: "false"}),
    /Invalid legacy wallet flag/,
  );
});

test("public user ID is server-derived rather than copied from legacy data", () => {
  const result = projectPublicProfile("verified-uid", {
    uid: "spoofed", username: "teacher", walletFrozen: true,
  });
  assert.deepEqual(result, {uid: "verified-uid", username: "teacher"});
});

test("only clean zero-balance signups may bootstrap a private wallet", () => {
  assert.equal(canBootstrapZeroWallet({coins: 0, diamonds: 0, username: "new"}), true);
  assert.equal(canBootstrapZeroWallet({coins: 1, diamonds: 0}), false);
  assert.equal(canBootstrapZeroWallet({coins: 0, diamonds: 0, walletFrozen: false}), false);
  assert.equal(canBootstrapZeroWallet({coins: 0, purchasedCoins: 0}), false);
  assert.equal(canBootstrapZeroWallet({coins: "0", diamonds: 0}), false);
  assert.equal(canBootstrapZeroWallet(null), false);
});
