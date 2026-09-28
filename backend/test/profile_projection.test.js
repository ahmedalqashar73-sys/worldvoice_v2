import test from "node:test";
import assert from "node:assert/strict";
import {projectPublicProfile, extractLegacyWallet} from "../src/profile_projection.js";

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
