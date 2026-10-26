import test from "node:test";
import assert from "node:assert/strict";

import {
  approvedWorldVoiceGift,
  worldVoiceGiftCatalog,
  worldVoiceGiftStoreDocument,
} from "../src/gift_catalog.js";

test("approved WorldVoice gift catalog is exactly 54 items", () => {
  assert.equal(worldVoiceGiftCatalog.size, 54);
  assert.equal(worldVoiceGiftCatalog.get("wv_gift_001")?.priceCoins, 1);
  assert.equal(worldVoiceGiftCatalog.get("wv_gift_054")?.priceCoins, 5000);

  const tierCounts = {1: 0, 2: 0, 3: 0};
  for (const item of worldVoiceGiftCatalog.values()) {
    tierCounts[item.tier] += 1;
  }
  assert.deepEqual(tierCounts, {1: 30, 2: 15, 3: 9});
});

test("gift settlement authority rejects unknown IDs and altered prices", () => {
  assert.ok(approvedWorldVoiceGift("wv_gift_010", 35));
  assert.equal(approvedWorldVoiceGift("wv_gift_010", 999), null);
  assert.equal(approvedWorldVoiceGift("classic_old_gift", 35), null);
});

test("store documents are generated from backend-owned prices", () => {
  const gift = worldVoiceGiftStoreDocument("wv_gift_048");
  assert.equal(gift.type, "gift");
  assert.equal(gift.active, true);
  assert.equal(gift.priceCoins, 1800);
  assert.equal(gift.tier, 3);
  assert.equal(gift.builtInVisual, true);
});
