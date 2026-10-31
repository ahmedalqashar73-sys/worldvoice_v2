import test from "node:test";
import assert from "node:assert/strict";
import {
  worldBondSpecialGiftCatalog,
  approvedWorldBondGift,
  worldVoiceGiftCatalog,
} from "../src/gift_catalog.js";
import {BOND_TYPES, bondKey} from "../src/world_bond_routes.js";

test("four relationship gifts have exact immutable prices and distinct art IDs", () => {
  assert.deepEqual(
    worldBondSpecialGiftCatalog.map(g => [g.id, g.level, g.priceCoins]),
    [
      ["wv_bond_01", 1, 100],
      ["wv_bond_02", 2, 200],
      ["wv_bond_03", 3, 500],
      ["wv_bond_04", 4, 1000],
    ],
  );
  assert.equal(new Set(worldBondSpecialGiftCatalog.map(g => g.id)).size, 4);
  for (const item of worldBondSpecialGiftCatalog) {
    assert.equal(Object.isFrozen(item), true);
    assert.equal(worldVoiceGiftCatalog.has(item.id), false);
    assert.equal(approvedWorldBondGift(item.id), item);
    assert.ok(item.name && item.nameAr);
  }
});

test("unknown or room catalog gift IDs cannot impersonate WorldBond gifts", () => {
  for (const id of ["wv_gift_023", "wv_bond_00", "wv_bond_05", "../private",
    "wv_bond_01_extra", "", null]) {
    assert.equal(approvedWorldBondGift(id), null);
  }
});

test("learning is separate from language and relationship IDs remain isolated", () => {
  assert.deepEqual(BOND_TYPES, ["learning", "language", "friend", "duo"]);
  assert.notEqual(bondKey("alice123", "bob456", "learning"),
    bondKey("alice123", "bob456", "language"));
  assert.equal(bondKey("alice123", "bob456", "learning"),
    bondKey("bob456", "alice123", "learning"));
});
