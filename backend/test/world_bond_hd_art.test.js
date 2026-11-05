import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {worldBondSpecialGiftCatalog} from '../src/gift_catalog.js';

test('four distinct relationship emblems and four shared HD gifts have alpha', () => {
  const names = ['badge_learning', 'badge_language', 'badge_friend', 'badge_duo',
    'gift_01', 'gift_02', 'gift_03', 'gift_04'];
  const hashes = new Set();
  for (const name of names) {
    const bytes = readFileSync(new URL(`../../assets/world_bond/${name}.webp`, import.meta.url));
    assert.equal(bytes.toString('ascii', 0, 4), 'RIFF', name);
    assert.equal(bytes.toString('ascii', 8, 12), 'WEBP', name);
    assert.equal(bytes.toString('ascii', 12, 16), 'VP8X', name);
    assert.ok(bytes[20] & 0x10, name);
    assert.ok(bytes.readUIntLE(24, 3) + 1 >= 1024, name);
    assert.ok(bytes.readUIntLE(27, 3) + 1 >= 1024, name);
    hashes.add(createHash('sha256').update(bytes).digest('hex'));
  }
  assert.equal(hashes.size, 8);
  assert.deepEqual(worldBondSpecialGiftCatalog.map(g => [g.id, g.level, g.priceCoins]), [
    ['wv_bond_01', 1, 100], ['wv_bond_02', 2, 200],
    ['wv_bond_03', 3, 500], ['wv_bond_04', 4, 1000],
  ]);
});
