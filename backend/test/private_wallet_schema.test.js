import test from "node:test";
import assert from "node:assert/strict";
import {
  PRIVATE_WALLET_FIELDS, legacyWalletSnapshot,
  containsLegacyWalletFields, assertMigrationConsistency,
} from "../src/private_wallet_schema.js";

test("private wallet fields do not include social gift level or display name", () => {
  assert.ok(PRIVATE_WALLET_FIELDS.includes("coins"));
  assert.ok(PRIVATE_WALLET_FIELDS.includes("identityVerified"));
  assert.ok(!PRIVATE_WALLET_FIELDS.includes("giftLevel"));
  assert.ok(!PRIVATE_WALLET_FIELDS.includes("displayName"));
});
test("migration keeps zero vs nonzero balances without resetting them", () => {
  const original={coins:500, diamonds:19, walletFrozen:true,
    identityVerified:true, displayName:"Visible",giftLevel:12};
  assert.equal(containsLegacyWalletFields(original),true);
  const wallet=legacyWalletSnapshot(original);
  assert.equal(wallet.coins,500);
  assert.equal(wallet.diamonds,19);
  assert.equal(wallet.walletFrozen,true);
  assert.equal(wallet.identityVerified,true);
  assert.equal(wallet.giftLevel,undefined);
  assert.equal(wallet.displayName,undefined);
  assert.doesNotThrow(() => assertMigrationConsistency(wallet, original));
});
test("migration fails closed on malformed or conflicting balances", () => {
  assert.throws(() => legacyWalletSnapshot({coins:-2}));
  assert.throws(() => legacyWalletSnapshot({diamonds:1.5}));
  assert.throws(() => assertMigrationConsistency({coins:20},{coins:21}));
  assert.equal(legacyWalletSnapshot({displayName:"New"}).coins,0);
});
