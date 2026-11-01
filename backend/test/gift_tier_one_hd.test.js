import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';

const catalog = JSON.parse(readFileSync(new URL('../../assets/gifts/worldvoice_gifts.json', import.meta.url)));

test('28 former atlas tier-one gifts have distinct transparent HD artwork', () => {
  const hashes = new Set();
  for (let number = 1; number <= 30; number++) {
    if (number === 2 || number === 26) continue; // Already upgraded earlier.
    const id = `wv_gift_${String(number).padStart(3, '0')}`;
    const gift = catalog.gifts.find(g => g.id === id);
    assert.equal(gift.tier, 1, id);
    assert.equal(gift.artAsset, `assets/gifts/hd/${id}.webp`, id);
    const bytes = readFileSync(new URL(`../../${gift.artAsset}`, import.meta.url));
    assert.equal(bytes.toString('ascii', 0, 4), 'RIFF', id);
    assert.equal(bytes.toString('ascii', 8, 12), 'WEBP', id);
    assert.equal(bytes.toString('ascii', 12, 16), 'VP8X', id);
    assert.ok(bytes[20] & 0x10, `alpha: ${id}`);
    assert.ok(bytes.readUIntLE(24, 3) + 1 >= 1024, `width: ${id}`);
    assert.ok(bytes.readUIntLE(27, 3) + 1 >= 1024, `height: ${id}`);
    hashes.add(createHash('sha256').update(bytes).digest('hex'));
  }
  assert.equal(hashes.size, 28);
  assert.equal(catalog.gifts.length, 104);
  assert.equal(new Set(catalog.gifts.map(g => g.id)).size, 104);
});
