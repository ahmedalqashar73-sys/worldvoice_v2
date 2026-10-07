import test from "node:test";
import assert from "node:assert/strict";
import {readFileSync} from "node:fs";
import {fileURLToPath} from "node:url";

const catalog = JSON.parse(readFileSync(fileURLToPath(
  new URL("../../assets/gifts/worldvoice_gifts.json", import.meta.url)
), "utf8"));

test("shared catalog has the approved 54 WorldVoice gifts", () => {
  assert.equal(catalog.catalogId, "worldvoice_gifts_v1");
  assert.equal(catalog.gifts.length, 54);
  assert.equal(new Set(catalog.gifts.map(g => g.id)).size, 54);
  assert.equal(catalog.atlas.columns, 9);
  assert.equal(catalog.atlas.rows, 6);
  assert.equal(catalog.atlas.cellSize, 192);
  assert.equal(catalog.atlas.source, "remote_original_quality");
  assert.match(catalog.atlas.url, /^https:\/\//);

  assert.deepEqual(
    catalog.gifts.map(g => g.sortOrder),
    Array.from({length: 54}, (_, i) => i + 1),
  );

  assert.equal(catalog.gifts.filter(g => g.tier === 1).length, 30);
  assert.equal(catalog.gifts.filter(g => g.tier === 2).length, 15);
  assert.equal(catalog.gifts.filter(g => g.tier === 3).length, 9);

  assert.ok(catalog.gifts.every(g =>
    /^wv_gift_[0-9]{3}$/.test(g.id) &&
    Number.isSafeInteger(g.priceCoins) &&
    g.priceCoins >= 1 && g.priceCoins <= 5000 &&
    typeof g.nameAr === "string" && g.nameAr.length > 0 &&
    typeof g.name === "string" && g.name.length > 0 &&
    typeof g.emoji === "string" && g.emoji.length > 0 &&
    typeof g.effectType === "string" && g.effectType.length > 0
  ));
});
