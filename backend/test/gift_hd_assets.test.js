import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {worldVoiceGiftCatalog} from '../src/gift_catalog.js';

const catalog = JSON.parse(readFileSync(new URL('../../assets/gifts/worldvoice_gifts.json', import.meta.url)));

test('50 unique new designs use sharp transparent HD assets', () => {
  const additions = catalog.gifts.slice(54);
  assert.equal(additions.length, 50);
  assert.equal(additions.filter(g => g.priceCoins <= 100).length, 20);
  assert.equal(additions.filter(g => g.priceCoins >= 150 && g.priceCoins <= 1000).length, 20);
  assert.equal(additions.filter(g => g.priceCoins > 1000).length, 10);
  assert.equal(new Set(additions.map(g => g.name)).size, 50);
  const hashes = new Set();
  for (const id of [2, 26, ...Array.from({length:50}, (_, i) => i + 55)]) {
    const name = `wv_gift_${String(id).padStart(3, '0')}`;
    const bytes = readFileSync(new URL(`../../assets/gifts/hd/${name}.webp`, import.meta.url));
    assert.equal(bytes.toString('ascii', 0, 4), 'RIFF', name);
    assert.equal(bytes.toString('ascii', 8, 12), 'WEBP', name);
    assert.equal(bytes.toString('ascii', 12, 16), 'VP8X', name);
    assert.ok(bytes[20] & 0x10, `alpha: ${name}`);
    assert.ok(bytes.readUIntLE(24, 3) + 1 >= 1024, `width: ${name}`);
    assert.ok(bytes.readUIntLE(27, 3) + 1 >= 1024, `height: ${name}`);
    hashes.add(createHash('sha256').update(bytes).digest('hex'));
  }
  assert.equal(hashes.size, 52);
});

test('all bundled gift prices match server settlement authority', () => {
  for (const gift of catalog.gifts) {
    const server = worldVoiceGiftCatalog.get(gift.id);
    assert.equal(server.priceCoins, gift.priceCoins, gift.id);
    assert.equal(server.tier, gift.tier, gift.id);
  }
});
