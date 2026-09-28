import test from "node:test";
import assert from "node:assert/strict";
import {
  PUBLIC_PROFILE_FIELDS, PRIVATE_WALLET_FIELDS, hasPrivateWalletFields,
  toPublicProfile, toPrivateWallet, walletCopyMatches,
} from "../src/profile_privacy.js";

const legacy = {
  uid: "u", displayName: "WorldVoice user", country: "SA",
  city: "Riyadh", hideCity: true, birthDate: "1990-01-01",
  email: "private@example.test", coins: 150, diamonds: 8,
  walletDebtCoins: 2, identityVerified: true, isVerified: true,
};
test("public profile never contains private finances or hidden location", () => {
  const pub = toPublicProfile("u", legacy);
  assert.equal(pub.displayName, legacy.displayName);
  for (const field of [...PRIVATE_WALLET_FIELDS, "birthDate",
    "email", "identityVerified", "city"]) {
    assert.equal(Object.hasOwn(pub, field), false, field);
  }
});
test("city requires explicit owner opt-in", () => {
  assert.equal(toPublicProfile("u", {...legacy, hideCity: false}).city, "Riyadh");
  assert.equal(toPublicProfile("u", {...legacy, hideCity: undefined}).city, undefined);
});
test("wallet projection is minimal and idempotent", () => {
  const wallet = toPrivateWallet("u", legacy);
  assert.equal(wallet.coins, 150);
  assert.equal(Object.hasOwn(wallet, "email"), false);
  assert.equal(walletCopyMatches({...wallet, schemaVersion: 1}, wallet), true);
  assert.equal(walletCopyMatches({...wallet, coins: 149}, wallet), false);
  assert.equal(hasPrivateWalletFields({displayName: "a"}), false);
  assert.equal(hasPrivateWalletFields(legacy), true);
  assert.ok(PRIVATE_WALLET_FIELDS.every(f => !PUBLIC_PROFILE_FIELDS.includes(f)));
});
