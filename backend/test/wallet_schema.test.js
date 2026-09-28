import test from "node:test";
import assert from "node:assert/strict";
import {
  projectWallet, projectPublicProfile, requireMigratedWallet,
} from "../src/wallet_schema.js";

test("private profile projection never exposes email, exact DOB or balances", () => {
  const input = {
    uid: "alice", email: "secret@example.test", displayName: "Alice",
    country: "SA", birthDate: new Date("2000-12-31T00:00:00Z"),
    coins: 999, diamonds: 200, payoutFreezeReason: "private",
    identityVerified: true, hideCity: true, city: "Secret",
  };
  const projected = projectPublicProfile(input, new Date("2026-09-28T00:00:00Z"));
  assert.deepEqual(projected, {
    uid: "alice", displayName: "Alice", country: "SA",
    hideCity: true, ageYears: 25,
  });
  for (const forbidden of [
    "email", "birthDate", "coins", "diamonds", "payoutFreezeReason",
    "identityVerified", "city",
  ]) assert.equal(Object.hasOwn(projected, forbidden), false);
});

test("wallet migration preserves balances and rejects invalid credits", () => {
  const migrated = projectWallet({
    coins: 140, diamondsPending: 25, walletFrozen: true,
  });
  assert.equal(migrated.schemaVersion, 1);
  assert.equal(migrated.coins, 140);
  assert.equal(migrated.diamonds, 0);
  assert.equal(migrated.diamondsPending, 25);
  assert.equal(migrated.walletFrozen, true);
  assert.throws(() => projectWallet({coins: -5}), /Invalid legacy wallet/);
  assert.throws(() => projectWallet({coins: 1.5}), /Invalid legacy wallet/);
});

test("economy refuses unmigrated or malformed wallets", () => {
  assert.throws(() => requireMigratedWallet({exists: false}), /not migrated/);
  assert.throws(() => requireMigratedWallet({
    exists: true, data: () => ({schemaVersion: 2}),
  }), /not migrated/);
  assert.equal(requireMigratedWallet({
    exists: true, data: () => ({schemaVersion: 1, coins: 0}),
  }).coins, 0);
});
