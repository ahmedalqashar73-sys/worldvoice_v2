import {readFile} from 'node:fs/promises';
import {before, beforeEach, after, test} from 'node:test';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, setDoc, updateDoc, writeBatch, serverTimestamp, increment} from 'firebase/firestore';

let env;
const user = uid => env.authenticatedContext(uid).firestore();
const live = db => doc(db, 'live_sessions/live_stage_test');
const guestRequest = db => doc(db, 'live_sessions/live_stage_test/join_requests/guest');

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-worldvoice-stage-rules',
    firestore: {rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8')},
  });
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(live(db), {
      channelId: 'live_stage_test', hostId: 'host',
      hostAgoraUid: 9876, isLive: true, isReady: true,
      viewerCount: 1, guestCount: 1, topic: 'English',
    });
    await setDoc(guestRequest(db), {
      uid: 'guest', displayName: 'Guest', photoUrl: '',
      status: 'accepted', decidedAt: serverTimestamp(),
    });
  });
});
after(async () => {await env?.cleanup();});

const lower = db => {
  const batch = writeBatch(db);
  batch.update(guestRequest(db), {
    status: 'removed', decidedAt: serverTimestamp(),
  });
  batch.update(live(db), {
    guestCount: increment(-1), updatedAt: serverTimestamp(),
  });
  return batch.commit();
};

test('host may lower a guest atomically but leaves their audience membership intact', async () => {
  await assertSucceeds(lower(user('host')));
});

test('guest or outsider cannot remove someone from the stage', async () => {
  await assertFails(lower(user('guest')));
  await assertFails(lower(user('stranger')));
});

test('host cannot mark removed without releasing stage capacity in same transaction', async () => {
  await assertFails(updateDoc(guestRequest(user('host')), {
    status: 'removed', decidedAt: serverTimestamp(),
  }));
});

test('host cannot alter another stage request while lowering the participant', async () => {
  const db = user('host');
  const batch = writeBatch(db);
  batch.update(guestRequest(db), {
    status: 'removed', displayName: 'forged',
    decidedAt: serverTimestamp(),
  });
  batch.update(live(db), {
    guestCount: increment(-1), updatedAt: serverTimestamp(),
  });
  await assertFails(batch.commit());
});
