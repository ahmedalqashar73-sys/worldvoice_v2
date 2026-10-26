import test from 'node:test';
import assert from 'node:assert/strict';
import {canManageStore} from '../src/economy_policy.js';

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
  source.indexOf('app.post("/store/claim-reward"'));
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
    authenticatedUser: async () => ({uid: 'sender'}), canManageStore,
    createHash: () => ({update: () => ({digest: () => 'operation'})}),
    db: {collection: name => ref(name), doc: ref,
      runTransaction: fn => fn({get: async r => ({exists: docs.has(r.path) && docs.get(r.path) != null,
        data: () => docs.get(r.path)}), set: (...args) => writes.push(args),
        create: (...args) => writes.push(args), update: (...args) => writes.push(args)})},
    privateWalletRef: r => ref(`${r.path}/private/wallet`),
    requirePrivateWallet: () => {throw new Error('Wallet required');},
    requireLiveEconomy: () => {throw new Error('Economy required');},
    builtInRoomBackground: () => null, builtInWorldVoiceFrame: () => item,
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


const backgroundRoute = source.slice(source.indexOf('app.post("/room/background/apply"'),
  source.indexOf('function isStageRole'));
async function applyBackground({themeId = 'wv_premium_01', owned = true,
  hostId = 'sender', expired = false} = {}) {
  let handler, status = 200, body;
  const writes = [];
  const ref = path => ({path, collection: name => ref(`${path}/${name}`),
    doc: id => ref(`${path}/${id}`),
    get: async () => path.startsWith('rooms/')
      ? {exists: true, data: () => ({isOpen: true, hostId})}
      : {exists: owned, data: () => ({themeId,
        expiresAt: expired ? {toMillis: () => 1} : null})},
    set: async value => {writes.push(value);}});
  vm.runInNewContext(backgroundRoute, {
    app: {post: (_, fn) => {handler = fn;}},
    authenticatedUser: async () => ({uid: 'sender'}),
    validChannelName: value => value === 'room1',
    worldVoiceRoomBackgroundPrices: new Map(Array.from({length: 8}, (_, i) =>
      [`background__wv_premium_0${i + 1}`, 150])),
    freeRoomBackgroundThemes: new Set(['softGreenFlow']),
    db: {collection: name => ref(name)},
    FieldValue: {delete: () => 'deleted', serverTimestamp: () => 'now'},
  });
  const res = {status: value => {status = value; return res;}, json: value => {body = value;}};
  await handler({body: {roomId: 'room1', themeId}}, res, error => {throw error;});
  return {status, body, writes};
}
test('all eight owned backgrounds apply with the current layout version', async () => {
  for (let i = 1; i <= 8; i++) {
    const themeId = `wv_premium_0${i}`;
    const result = await applyBackground({themeId});
    assert.equal(result.status, 200);
    assert.equal(result.writes[0].themeId, themeId);
    assert.equal(result.writes[0].backgroundLayoutVersion, 4);
  }
});
test('background application preserves host and ownership restrictions', async () => {
  for (const args of [{owned: false}, {expired: true}, {hostId: 'other'}]) {
    const result = await applyBackground(args);
    assert.equal(result.status, 403);
    assert.equal(result.writes.length, 0);
  }
  assert.equal((await applyBackground({themeId: 'wv_bg_06'})).status, 400);
  assert.equal((await applyBackground({themeId: 'softGreenFlow', owned: false})).status, 200);
});
