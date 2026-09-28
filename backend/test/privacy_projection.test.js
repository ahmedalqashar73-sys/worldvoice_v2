import test from "node:test";
import assert from "node:assert/strict";
import {
  projectPrivateWallet, projectPublicProfile, assertPublicProjectionSafe,
} from "../src/privacy_projection.js";

test("balances are only in the private wallet; unknown secrets never leak", () => {
  const source = {
    displayName: "Example", username: "example", bio: "Languages",
    coins: 500, diamonds: 4, diamondsPending: 3, walletDebtCoins: 0,
    bankAccount: "SECRET", email: "private@example.com",
    birthDate: "1990-01-01", phoneNumber: "SECRET",
    identityVerified: true, customFinanceThing: 999,
  };
  const wallet = projectPrivateWallet(source);
  const publicProfile = projectPublicProfile(source, "user1");
  assert.equal(wallet.coins, 500);
  assert.equal(wallet.diamonds, 4);
  assert.equal(wallet.identityVerified, true);
  assert.equal(publicProfile.displayName, "Example");
  assert.equal(publicProfile.uid, "user1");
  for (const field of [
    "coins", "diamonds", "diamondsPending", "walletDebtCoins",
    "bankAccount", "email", "birthDate", "phoneNumber",
    "identityVerified", "customFinanceThing",
  ]) assert.equal(field in publicProfile, false, field);
  assert.equal(assertPublicProjectionSafe(publicProfile), true);
});

test("city is private unless user explicitly opts in", () => {
  assert.equal(projectPublicProfile({city: "Riyadh"}, "u").city, undefined);
  assert.equal(projectPublicProfile({city: "Riyadh", hideCity: true}, "u").city, undefined);
  assert.equal(projectPublicProfile({city: " Riyadh ", hideCity: false}, "u").city, "Riyadh");
});

test("wallet rejects impossible or fractional existing balances", () => {
  assert.throws(() => projectPrivateWallet({coins: -1}), /Invalid legacy wallet/);
  assert.throws(() => projectPrivateWallet({diamonds: 1.5}), /Invalid legacy wallet/);
  assert.throws(() => projectPrivateWallet({walletDebtCoins: Number.MAX_SAFE_INTEGER + 1}), /Invalid legacy wallet/);
});

test("public profile allowlist rejects accidental new private keys", () => {
  assert.throws(
    () => assertPublicProjectionSafe({uid: "u", schemaVersion: 1, coins: 1}),
    /Unexpected public profile field/,
  );
  assert.throws(() => projectPublicProfile({}, ""), /UID/);
});
