import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';

const catalog = JSON.parse(readFileSync(new URL('../../assets/gifts/worldvoice_gifts.json', import.meta.url)));

test('all 35 medium gifts use distinct transparent HD assets', () => {
  const medium = catalog.gifts.filter(g => g.tier === 2);
  assert.equal(medium.length, 35);
  const hashes = new Set();
  for (const gift of medium) {
    assert.equal(gift.artAsset, `assets/gifts/hd/${gift.id}.webp`);
    const bytes = readFileSync(new URL(`../../${gift.artAsset}`, import.meta.url));
    assert.equal(bytes.toString('ascii', 0, 4), 'RIFF', gift.id);
    assert.equal(bytes.toString('ascii', 8, 12), 'WEBP', gift.id);
    assert.equal(bytes.toString('ascii', 12, 16), 'VP8X', gift.id);
    assert.ok(bytes[20] & 0x10, `alpha: ${gift.id}`);
    assert.ok(bytes.readUIntLE(24, 3) + 1 >= 1024, `width: ${gift.id}`);
    assert.ok(bytes.readUIntLE(27, 3) + 1 >= 1024, `height: ${gift.id}`);
    hashes.add(createHash('sha256').update(bytes).digest('hex'));
  }
  assert.equal(hashes.size, 35);
  assert.equal(catalog.gifts.length, 104);
});
