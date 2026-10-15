import test from 'node:test';
import assert from 'node:assert/strict';
import {initializeApp, deleteApp} from 'firebase-admin/app';
import {getFirestore, Timestamp} from 'firebase-admin/firestore';
import {registerRoomTaskRoutes} from '../src/room_task_routes.js';
import {roomXpThresholdForLevel} from '../src/room_task_policy.js';

// Real transactions against an isolated demo emulator only; never production.
test('room mission routes: emulator transactions and replay safety',
  {skip: !process.env.FIRESTORE_EMULATOR_HOST}, async t => {
  const app = initializeApp({projectId: 'demo-worldvoice-rules'}, 'room-task-tests');
  const db = getFirestore(app);
  const routes = new Map();
  registerRoomTaskRoutes({db, app: {
    get: (path, handler) => routes.set(path, handler),
    post: (path, handler) => routes.set(path, handler),
  }, authenticatedUser: async req => ({uid: req.uid})});
  let sequence = 0;
  const uid = 'mission-host';
  async function seed(xp = 0, extra = {}) {
    const roomId = `mission-${Date.now()}-${++sequence}`;
    const room = db.collection('rooms').doc(roomId);
    await room.set({hostId: uid, isOpen: true, roomXp: xp,
      roomCastleXpVersion: 2, ...extra});
    await join(room, uid, 600000);
    return {room, roomId};
  }
  async function join(room, id, activeMs = 0) {
    const now = Date.now();
    await room.collection('participants').doc(id).set({
      joinedAt: Timestamp.fromMillis(now - activeMs - 1000),
      updatedAt: Timestamp.fromMillis(now), kicked: false,
    });
    await room.collection('task_attendance').doc(id).set({
      day: new Date(now).toISOString().slice(0, 10),
      lastSeenMs: now, joinedAtMs: now - activeMs - 1000, activeMs,
    });
  }
  async function call(path, roomId, taskKey, caller = uid) {
    let result;
    const res = {statusCode: 200, status(code) {this.statusCode = code; return this;},
      json(body) {result = {status: this.statusCode, body}; return this;}};
    await routes.get('/room/tasks/' + path)({uid: caller,
      body: {roomId, taskKey}, query: {roomId}}, res,
      error => {result = {status: error.status ?? 500, body: {error: error.message}};});
    return result;
  }
  try {
    await t.test('heartbeat advances creative evidence without claiming XP again', async () => {
      const {room, roomId} = await seed();
      const now = Date.now();
      const cycle = db.doc(`users/${uid}/engagement/cycle`);
      await cycle.set({startDay: Math.floor(now / 86400000), claimedDays: 3,
        activeMs: 3590000, lastPresenceMs: now - 30000});
      await room.collection('task_attendance').doc(uid).update({lastSeenMs: now - 30000});
      for (let i = 0; i < 5; i++) await join(room, `creative-guest-${i}`);
      assert.equal((await call('heartbeat', roomId)).status, 200);
      const data = (await cycle.get()).data();
      assert.equal(data.hostedFive, true);
      assert.equal(data.activeMs, 3600000);
      assert.equal(data.creativeCycles, 1);
      await call('heartbeat', roomId);
      assert.equal((await cycle.get()).data().creativeCycles, 1);
      assert.equal((await room.get()).data().roomXp, 0);
      await cycle.delete();
    });
    await t.test('host heartbeat finds five guests beyond stale first page', async () => {
      const {room, roomId} = await seed();
      const now = Date.now();
      const startDay = Math.floor(now / 86400000);
      const cycle = db.doc(`users/${uid}/engagement/cycle`);
      await cycle.set({startDay, claimedDays: 3, activeMs: 3600000});
      // Place 30 invalid newer attendance records before five real guests.
      // The paginated scanner must continue past these records.
      const batch = db.batch();
      for (let i = 0; i < 30; i++) {
        batch.set(room.collection('task_attendance').doc(`stale-${i}`), {
          lastSeenMs: now + 5000, day: new Date(now).toISOString().slice(0, 10),
          activeMs: 900000,
        });
      }
      await batch.commit();
      for (let i = 0; i < 5; i++) await join(room, `late-guest-${i}`);
      assert.equal((await call('heartbeat', roomId)).status, 200);
      const status = await call('status', roomId);
      assert.equal(status.status, 200);
      assert.equal(status.body.progress.guestCount, 5);
      assert.equal(status.body.missions.find(task => task.key === 'host_five').eligible, true);
      const result = (await cycle.get()).data();
      assert.equal(result.hostedFive, true);
      assert.equal(result.creativeCycles, 1);
      assert.equal((await room.get()).data().roomXp, 0);
    });
    await t.test('concurrent requests award XP exactly once', async () => {
      const {room, roomId} = await seed();
      const responses = await Promise.all(Array.from({length: 8}, () =>
        call('claim', roomId, 'ten_minutes')));
      assert.ok(responses.every(r => r.status === 200), JSON.stringify(responses));
      assert.equal(responses.filter(r => !r.body.alreadyProcessed).length, 1);
      assert.equal((await room.get()).data().roomXp, 4);
      assert.equal((await room.collection('task_completions').get()).size, 1);
      const status = await call('status', roomId);
      assert.equal(status.body.missions[0].eligible, false);
    });
    await t.test('forged client times and missing heartbeats earn nothing', async () => {
      const {room, roomId} = await seed();
      await room.collection('task_attendance').doc(uid).delete();
      assert.equal((await call('claim', roomId, 'ten_minutes')).status, 409);
      assert.equal((await call('heartbeat', roomId)).status, 200);
      assert.equal((await call('status', roomId)).body.progress.minutes, 0);
      assert.equal((await call('claim', roomId, 'ten_minutes')).status, 409);
    });
    await t.test('five verified guests are counted beyond abandoned records', async () => {
      const {room, roomId} = await seed();
      for (let i = 0; i < 10; i++) {
        await room.collection('participants').doc(`aaa-stale-${i}`).set({});
      }
      for (let i = 0; i < 5; i++) await join(room, `guest-${i}`);
      assert.equal((await call('status', roomId)).body.progress.guestCount, 5);
      assert.equal((await call('claim', roomId, 'host_five')).status, 200);
      assert.equal((await room.get()).data().roomXp, 50);
      assert.equal((await call('claim', roomId, 'host_five', 'guest-0')).status, 403);
    });
    await t.test('host task claim pages past stale attendance without milestone fanout', async () => {
      const {room, roomId} = await seed();
      const now = Date.now();
      const batch = db.batch();
      // Recent-looking attendance rows with no matching live participants
      // must not conceal five real guests on a later page.
      for (let i = 0; i < 30; i++) {
        batch.set(room.collection('task_attendance').doc(`stale-claim-${i}`), {
          lastSeenMs: now + 5000,
          day: new Date(now).toISOString().slice(0, 10),
          joinedAtMs: now - 600000, activeMs: 600000,
        });
      }
      await batch.commit();
      for (let i = 0; i < 5; i++) await join(room, `paged-claim-guest-${i}`);
      const outcome = await call('claim', roomId, 'host_five');
      assert.equal(outcome.status, 200, JSON.stringify(outcome));
      assert.equal(outcome.body.awardedXp, 50);
      assert.equal((await room.get()).data().roomXp, 50);
      assert.equal((await call('claim', roomId, 'host_five')).body.alreadyProcessed, true);
    });
    await t.test('departed or kicked guests do not qualify', async () => {
      const {room, roomId} = await seed();
      for (let i = 0; i < 5; i++) await join(room, `guest-${i}`);
      await room.collection('participants').doc('guest-0').delete();
      await room.collection('participants').doc('guest-1').update({kicked: true});
      assert.equal((await call('status', roomId)).body.progress.guestCount, 3);
      assert.equal((await call('claim', roomId, 'host_five')).status, 409);
      assert.equal((await call('heartbeat', roomId, null, 'guest-1')).status, 403);
    });
    await t.test('only verified gift records satisfy the gift mission', async () => {
      const {room, roomId} = await seed();
      await room.collection('gift_previews').doc(uid).set({senderId: uid, quantity: 100});
      assert.equal((await call('claim', roomId, 'three_gifts')).status, 409);
      for (let i = 0; i < 3; i++) {
        await room.collection('gifts').doc(`gift-${i}`).set({senderId: uid});
      }
      assert.equal((await call('claim', roomId, 'three_gifts')).body.awardedXp, 20);
      assert.equal((await call('claim', roomId, 'three_gifts')).body.alreadyProcessed, true);
    });
    await t.test('rejoining cannot reuse a previous session heartbeat', async () => {
      const {room, roomId} = await seed();
      await room.collection('participants').doc(uid).update({joinedAt: Timestamp.now()});
      assert.equal((await call('status', roomId)).body.missions[0].eligible, false);
      assert.equal((await call('claim', roomId, 'ten_minutes')).status, 409);
      assert.equal((await call('heartbeat', roomId)).status, 200);
      assert.equal((await call('claim', roomId, 'ten_minutes')).status, 200);
    });
    await t.test('two-hour mission needs server-observed time', async () => {
      const {room, roomId} = await seed();
      assert.equal((await call('claim', roomId, 'stay_hours')).status, 409);
      await join(room, uid, 7200000);
      assert.equal((await call('claim', roomId, 'stay_hours')).body.awardedXp, 15);
    });
    await t.test('legacy XP is preserved and migrated once', async () => {
      const {room, roomId} = await seed(100, {roomCastleXpVersion: 1});
      assert.equal((await call('claim', roomId, 'ten_minutes')).status, 200);
      const data = (await room.get()).data();
      assert.equal(data.roomXp, 304);
      assert.equal(data.legacyRoomXp, 100);
      assert.equal(data.roomCastleXpVersion, 2);
      await call('claim', roomId, 'ten_minutes');
      assert.equal((await room.get()).data().roomXp, 304);
    });
    await t.test('cap and unsupported migration versions fail without writes', async () => {
      for (const data of [{roomXp: roomXpThresholdForLevel(50)},
        {roomCastleXpVersion: 999}]) {
        const {room, roomId} = await seed(0, data);
        assert.equal((await call('claim', roomId, 'ten_minutes')).status, 409);
        assert.equal((await room.collection('task_completions').get()).size, 0);
      }
    });
    await t.test('reward retry recovers failed fanout without adding new recipients', async () => {
      const {room, roomId} = await seed(roomXpThresholdForLevel(5) - 4);
      await join(room, 'original-guest');
      const originalBatch = db.batch.bind(db);
      db.batch = () => {
        const batch = originalBatch();
        batch.commit = async () => {throw new Error('simulated fanout interruption');};
        return batch;
      };
      try {
        assert.equal((await call('claim', roomId, 'ten_minutes')).status, 500);
      } finally { db.batch = originalBatch; }
      await join(room, 'late-guest');
      await room.collection('participants').doc('original-guest').delete();
      const retry = await call('claim', roomId, 'ten_minutes');
      assert.equal(retry.status, 200);
      assert.equal(retry.body.alreadyProcessed, true);
      const reward = id => db.doc(`users/${id}/room_rewards/${roomId}_level_5`);
      assert.equal((await reward('original-guest').get()).exists, true);
      assert.equal((await reward('late-guest').get()).exists, false);
      const first = (await reward(uid).get()).data();
      await call('claim', roomId, 'ten_minutes');
      const second = (await reward(uid).get()).data();
      assert.equal(first.expiresAt.toMillis(), second.expiresAt.toMillis());
      assert.equal(first.grantedAt.toMillis(), second.grantedAt.toMillis());
    });
  } finally {await deleteApp(app);}
});
