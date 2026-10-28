import test from 'node:test';
import assert from 'node:assert/strict';
import {readStoryActivity} from '../src/story_activity.js';

function fixture(size = 3) {
  const all = Array.from({length: size}, (_, i) => ({id: `viewer${i}`,
    exists: true, data: () => ({displayName: `Person ${i}`, photoUrl: `https://example.com/${i}`,
      viewedAt: {toMillis: () => 10000 - i}})}));
  let offset = 0;
  const views = {orderBy: () => views, limit: () => views,
    startAfter: snap => {offset = all.findIndex(d => d.id === snap.id) + 1; return views;},
    doc: id => ({get: async () => all.find(d => d.id === id) || {exists: false}}),
    get: async () => ({docs: all.slice(offset, offset + 60)}),
    count: () => ({get: async () => ({data: () => ({count: size})})})};
  return {collection: name => {
    if (name === 'views') return views;
    assert.equal(name, 'likes');
    return {doc: id => ({get: async () => ({exists: id === 'viewer1'})})};
  }};
}

test('viewer cannot retrieve identities, totals, or likes of other viewers', async () => {
  const forbidden = {collection() {throw new Error('private data accessed');}};
  assert.deepEqual(await readStoryActivity(forbidden, 'owner', 'guest'), {});
});
test('owner sees each viewer and that viewer’s current like status', async () => {
  const data = await readStoryActivity(fixture(), 'owner', 'owner');
  assert.equal(data.viewsCount, 3);
  assert.equal(data.viewers[1].liked, true);
  assert.equal(data.viewers[0].liked, false);
  assert.equal(data.viewers[0].viewedAt, 10000);
  assert.equal(data.nextViewCursor, null);
});
test('owner can page past first sixty viewers without losing total', async () => {
  const first = await readStoryActivity(fixture(65), 'owner', 'owner');
  assert.equal(first.viewers.length, 60);
  assert.equal(first.viewsCount, 65);
  const second = await readStoryActivity(fixture(65), 'owner', 'owner', first.nextViewCursor);
  assert.equal(second.viewers.length, 5);
  assert.equal(second.viewers[0].uid, 'viewer60');
  assert.equal(second.nextViewCursor, null);
});
test('cursor cannot escape this story’s viewer collection', async () => {
  await assert.rejects(readStoryActivity(fixture(), 'owner', 'owner', '../other'),
    {status: 400});
});
