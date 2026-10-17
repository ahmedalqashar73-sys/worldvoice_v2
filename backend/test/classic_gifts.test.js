import test from "node:test";
import assert from "node:assert/strict";
import {readFileSync} from "node:fs";
import {fileURLToPath} from "node:url";

const catalog = JSON.parse(readFileSync(fileURLToPath(
  new URL("../../assets/gifts/classic_premium_1_50.json", import.meta.url)
), "utf8"));

test("shared catalog has 30 approved first-tier designs", () => {
  assert.equal(catalog.catalogId, "classic_1_50");
  assert.equal(catalog.gifts.length, 30);
  assert.equal(new Set(catalog.gifts.map(g => g.id)).size, 30);
  assert.deepEqual(
    catalog.gifts.map(g => g.sortOrder),
    Array.from({length: 30}, (_, i) => i + 1),
  );
  assert.ok(catalog.gifts.every(g =>
    /^classic_[a-z0-9_]+$/.test(g.id) &&
    Number.isSafeInteger(g.priceCoins) &&
    g.priceCoins >= 1 && g.priceCoins <= 50 &&
    typeof g.nameAr === "string" && g.nameAr.length > 0 &&
    typeof g.name === "string" && g.name.length > 0 &&
    typeof g.emoji === "string" && g.emoji.length > 0 &&
    typeof g.effectType === "string" && g.effectType.length > 0
  ));
  assert.equal(catalog.gifts.find(
    g => g.id === "classic_luminous_butterfly").priceCoins, 20);
  assert.equal(catalog.gifts.find(
    g => g.id === "classic_golden_phoenix").priceCoins, 50);
});
