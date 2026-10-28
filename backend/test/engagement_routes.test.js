import test from 'node:test';
import assert from 'node:assert/strict';
import {initializeApp, deleteApp} from 'firebase-admin/app';
import {getFirestore, Timestamp} from 'firebase-admin/firestore';
import {registerEngagementRoutes, engagementRef} from '../src/engagement_routes.js';
import {DAY_MS} from '../src/engagement_policy.js';
test('engagement transactions in demo emulator', {skip: !process.env.FIRESTORE_EMULATOR_HOST}, async t => {
  const firebase = initializeApp({projectId: 'demo-worldvoice-rules'}, 'engagement-tests');
  const db = getFirestore(firebase), routes = new Map();
  let now = 21000 * DAY_MS, sequence = 0;
  registerEngagementRoutes({db, clock: () => now, authenticatedUser: async req => {
    if (!req.uid) throw Object.assign(new Error('Unauthorized'), {status: 401});
    return {uid: req.uid};
  }, app: {get: (p, h) => routes.set(p, h), post: (p, h) => routes.set(p, h)}});
  async function call(path, uid, body = {}, query = {}) {
    let response;
    const res = {statusCode: 200, status(code) {this.statusCode = code; return this;},
      json(body) {response = {status: this.statusCode, body}; return this;}};
    await routes.get('/engagement/' + path)({uid, body, query}, res,
      error => {response = {status: error.status ?? 500, error: error.message};});
    return response;
  }
  const inventory = uid => db.doc(`users/${uid}/inventory/gift__wv_gift_001`);
  async function seed() {
    const uid = `cycle-${Date.now()}-${++sequence}`;
    await db.doc(`users/${uid}`).set({coins: 77});
    await db.doc('store_items/gift__wv_gift_001').set({active: true, type: 'gift', priceCoins: 1});
    return uid;
  }
  try {
    await t.test('eight concurrent claims grant exactly one gift without wallet changes', async () => {
      const uid = await seed(), body = {startDay: Math.floor(now / DAY_MS), day: 1};
      const responses = await Promise.all(Array.from({length: 8}, () => call('claim', uid, body)));
      assert.ok(responses.every(r => r.status === 200), JSON.stringify(responses));
      assert.equal(responses.filter(r => !r.body.alreadyProcessed).length, 1);
      assert.equal((await inventory(uid).get()).data().freeGiftBalance, 1);
      assert.equal((await db.doc(`users/${uid}`).get()).data().coins, 77);
    });
    await t.test('days 1/2/3, rest, stale retry and next cycle preserve inventory', async () => {
      const uid = await seed(), startDay = Math.floor(now / DAY_MS);
      for (let day = 1; day <= 3; day++) {
        now = (startDay + day - 1) * DAY_MS;
        assert.equal((await call('claim', uid, {startDay, day})).status, 200);
      }
      assert.equal((await inventory(uid).get()).data().freeGiftBalance, 6);
      now = (startDay + 3) * DAY_MS;
      assert.equal((await call('status', uid)).body.phase, 'rest');
      assert.equal((await call('claim', uid, {startDay, day: 3})).status, 409);
      now += DAY_MS;
      assert.equal((await call('claim', uid, {startDay, day: 1})).status, 409);
      assert.equal((await call('claim', uid, {startDay: startDay + 4, day: 1})).status, 200);
      assert.equal((await inventory(uid).get()).data().freeGiftBalance, 7);
    });
    await t.test('client cannot forge badge evidence; public response excludes private state', async () => {
      const uid = await seed(), startDay = Math.floor(now / DAY_MS);
      await call('claim', uid, {startDay, day: 1, activeMs: 3600000, hostedFive: true, creativeCycles: 99});
      assert.equal((await engagementRef(db, uid).get()).data().creativeCycles, undefined);
      const result = await call('badges', uid, {}, {userIds: uid});
      assert.deepEqual(Object.keys(result.body.badges[uid]).sort(),
        ['completedCycles', 'creativeAwardedAtMs', 'creativeCycles', 'giftLevel', 'vipBadge']);
      assert.equal((await call('status', null)).status, 401);
    });
    await t.test('third claim awards badge atomically only with server evidence', async () => {
      const uid = await seed(), startDay = Math.floor(now / DAY_MS) - 2;
      await engagementRef(db, uid).set({startDay, claimedDays: 2, activeMs: 3600000, hostedFive: true});
      await call('claim', uid, {startDay, day: 3});
      await call('claim', uid, {startDay, day: 3});
      const data = (await engagementRef(db, uid).get()).data();
      assert.equal(data.creativeCycles, 1);
      assert.equal(data.completedCycles, 1);
    });
    await t.test('unavailable catalog and timed inventory fail without consuming a day', async () => {
      const uid = await seed(), body = {startDay: Math.floor(now / DAY_MS), day: 1};
      await db.doc('store_items/gift__wv_gift_001').update({active: false});
      assert.equal((await call('claim', uid, body)).status, 503);
      assert.equal((await engagementRef(db, uid).get()).exists, false);
      await db.doc('store_items/gift__wv_gift_001').update({active: true});
      await inventory(uid).set({freeGiftBalance: 5, expiresAt: Timestamp.fromMillis(now + DAY_MS)});
      assert.equal((await call('claim', uid, body)).status, 409);
      assert.equal((await inventory(uid).get()).data().freeGiftBalance, 5);
    });
  } finally { await deleteApp(firebase); }
});
