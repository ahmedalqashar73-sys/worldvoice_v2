import test from "node:test";
import assert from "node:assert/strict";
import {projectPublicProfile, extractLegacyWallet, assertExistingProjectionMatches} from "../src/profile_projection.js";

test("public projection is allowlisted, with no balances or private fields", () => {
  assert.deepEqual(projectPublicProfile("user1", {
    uid: "user1", displayName: "Alice", countryCode: "YE",
    coins: 500, diamonds: 5, city: "hidden", birthDate: "2000-01-01",
  }), {uid: "user1", displayName: "Alice", countryCode: "YE"});
});

test("private wallet copies only known economy fields", () => {
  assert.deepEqual(extractLegacyWallet({
    coins: 100, diamonds: 9, walletFrozen: false, displayName: "Alice",
  }), {coins: 100, diamonds: 9, walletFrozen: false});
});

test("invalid legacy balances halt the migration", () => {
  assert.throws(() => extractLegacyWallet({coins: -5}));
  assert.throws(() => extractLegacyWallet({diamonds: 2.5}));
  assert.throws(() => projectPublicProfile("a", {uid: "b"}));
});

test("existing wallet and profile are verified before staging resumes", () => {
  assert.equal(assertExistingProjectionMatches(
    {coins: 100, walletFrozen: false},
    {coins: 100, walletFrozen: false,
      migrationSource: "legacy_users", stagedAt: "internal"},
    "wallet"), true);
  assert.throws(() => assertExistingProjectionMatches(
    {coins: 100}, {coins: 101}, "wallet"), /reconcile/);
  assert.throws(() => assertExistingProjectionMatches(
    {walletFrozen: false}, {walletFrozen: 0}, "wallet"), /reconcile/);
  assert.throws(() => assertExistingProjectionMatches(
    {uid: "person"}, {uid: "other"}, "public"), /reconcile/);
});
