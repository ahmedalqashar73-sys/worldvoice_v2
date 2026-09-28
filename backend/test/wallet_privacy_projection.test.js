import test from "node:test";
import assert from "node:assert/strict";
import {
  projectPrivateWallet, projectPublicProfile, PRIVATE_WALLET_FIELDS,
} from "../src/wallet_privacy_projection.js";

test("public profiles never contain private wallet fields or location/DOB", () => {
  const legacy = {
    uid: "alice", displayName: "Alice", username: "learner",
    coins: 150, diamonds: 99, diamondsPending: 9,
    walletDebtCoins: 2, walletFrozen: true,
    dateOfBirth: "2000-01-01", city: "hidden-city",
    profileImageUrl: "https://example.invalid/profile.png",
    email: "private@example.invalid",
  };
  const publicProfile = projectPublicProfile(legacy, "alice");
  for (const field of PRIVATE_WALLET_FIELDS) {
    assert.equal(Object.hasOwn(publicProfile, field), false, field);
  }
  for (const field of ["dateOfBirth", "city", "email"]) {
    assert.equal(Object.hasOwn(publicProfile, field), false, field);
  }
  assert.equal(publicProfile.username, "learner");
  assert.equal(publicProfile.uid, "alice");
  const privateWallet = projectPrivateWallet(legacy, "alice");
  assert.equal(privateWallet.coins, 150);
  assert.equal(privateWallet.walletFrozen, true);
  assert.equal(Object.hasOwn(privateWallet, "email"), false);
});

test("bad legacy monetary values abort rather than migrate bad balances", () => {
  assert.throws(() => projectPrivateWallet({coins: -2}, "alice"));
  assert.throws(() => projectPrivateWallet({diamonds: 0.3}, "alice"));
  assert.throws(() => projectPrivateWallet({walletFrozen: "false"}, "alice"));
  assert.throws(() => projectPrivateWallet({}, ""));
});

test("public projector only copies explicit allowlisted fields", () => {
  const malicious = {
    uid: "alice", displayName: "A",
    apiKey: "secret", bankAccount: "secret",
    diamonds: 500, walletFrozen: false,
  };
  assert.deepEqual(projectPublicProfile(malicious, "alice"), {
    uid: "alice", projectionVersion: 1, displayName: "A",
  });
});
