import test from 'node:test';
import assert from 'node:assert/strict';
import {canManageStore, canGrantStoreCosmetic} from '../src/economy_policy.js';

test('cosmetic grants require active server-owned store permission', () => {
  for (const value of [undefined, {}, {isAdmin: true}, {role: 'host', active: true},
    {role: 'super_admin', active: false}, {active: true, permissions: 'manage_store'},
    {active: true, permissions: ['manage_rooms']}]) {
    assert.equal(canManageStore(value), false);
  }
  assert.equal(canManageStore({active: true, role: 'super_admin'}), true);
  assert.equal(canManageStore({active: true, permissions: ['manage_store']}), true);
});

// Exercise the actual route with an in-memory transaction; no live account writes.
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
const source = readFileSync(new URL('../src/server.js', import.meta.url), 'utf8');
const route = source.slice(source.indexOf('app.post(["/store/purchase"'),
  source.indexOf('app.post("/store/bubble/equip"'));
async function request({admin, path = '/store/admin-grant', recipientId} = {}) {
  const writes = [];
  const item = {type: 'frame', active: true, priceCoins: 360, name: 'Frame'};
  const docs = new Map([
    ['admins/sender', admin], ['users/sender', {}], ['users/friend', {}],
    ['users/sender/following/friend', {}], ['store_items/frame__test', item],
  ]);
  const ref = path => ({path, collection: name => ref(`${path}/${name}`),
    doc: id => ref(`${path}/${id}`)});
  let handler;
  vm.runInNewContext(route, {
    app: {post: (_, fn) => {handler = fn;}},
    authenticatedUser: async () => ({uid: 'sender'}), canManageStore, canGrantStoreCosmetic,
    createHash: () => ({update: () => ({digest: () => 'operation'})}),
    db: {collection: name => ref(name), doc: ref,
      runTransaction: fn => fn({get: async r => ({exists: docs.has(r.path) && docs.get(r.path) != null,
        data: () => docs.get(r.path)}), set: (...args) => writes.push(args),
        create: (...args) => writes.push(args), update: (...args) => writes.push(args)})},
    privateWalletRef: r => ref(`${r.path}/private/wallet`),
    requirePrivateWallet: () => {throw new Error('Wallet required');},
    requireLiveEconomy: () => {throw new Error('Economy required');},
    builtInRoomBackground: () => null, builtInWorldVoiceFrame: () => item,
    builtInChatBubble: () => null, chatBubbleInventoryId: () => null,
    FieldValue: {serverTimestamp: () => 'now'},
    Timestamp: {fromMillis: value => ({toMillis: () => value})},
  });
  let result, error;
  const res = {json: value => {result = value;}, status: () => res};
  await handler({path, body: {itemId: 'frame__test', recipientId, adminGrant: true},
    headers: {'idempotency-key': 'unique-request-key'}}, res, e => {error = e;});
  return {writes, result, error};
}
test('authorized cosmetic grants need no wallet and record zero-cost audit', async () => {
  for (const recipientId of [undefined, 'friend']) {
    const r = await request({admin: {active: true, permissions: ['manage_store']}, recipientId});
    assert.equal(r.error, undefined);
    assert.equal(r.result.paidCoins, 0);
    assert.ok(r.writes.some(([ref]) => ref.path.startsWith('economy_audit/')));
    assert.ok(r.writes.every(([ref]) => !ref.path.includes('/private/wallet')));
  }
});
test('revoked admin and client-only admin flags cannot grant cosmetics', async () => {
  for (const admin of [undefined, {active: false, role: 'super_admin'}, {isAdmin: true}]) {
    const r = await request({admin});
    assert.equal(r.error.status, 403);
    assert.equal(r.writes.length, 0);
  }
});
test('ordinary purchase keeps economy gates even with an adminGrant body flag', async () => {
  const r = await request({path: '/store/purchase', admin: {active: true, role: 'super_admin'}});
  assert.match(r.error.message, /Economy required/);
  assert.equal(r.writes.length, 0);
});
