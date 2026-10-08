import test from "node:test";
import assert from "node:assert/strict";
import {privateWalletRef, requirePrivateWallet} from "../src/wallet_store.js";

test("private wallet reference is scoped to the user's owner-only location", () => {
  const ref = {
    parent: {id: "users"},
    collection: name => ({
      doc: id => ({path: "users/member1/" + name + "/" + id}),
    }),
  };
  assert.equal(privateWalletRef(ref).path, "users/member1/private/wallet");
  assert.throws(() => privateWalletRef({parent: {id: "rooms"}}));
});

test("missing migrated wallets cannot start financial operations", () => {
  assert.throws(() => requirePrivateWallet({exists: false}), error =>
    error.status === 503);
});

test("invalid balance values require reconciliation", () => {
  for (const invalid of [{coins: -1}, {diamonds: 1.5},
    {diamondsPending: -3}, {walletDebtCoins: "9"}]) {
    assert.throws(() => requirePrivateWallet({
      exists: true, data: () => invalid,
    }), error => error.status === 503);
  }
});

test("well-formed migrated wallets are accepted", () => {
  assert.deepEqual(requirePrivateWallet({
    exists: true, data: () => ({
      coins: 100, diamonds: 5, diamondsPending: 0,
      walletDebtCoins: 0,
    }),
  }), {coins: 100, diamonds: 5, diamondsPending: 0, walletDebtCoins: 0});
});
