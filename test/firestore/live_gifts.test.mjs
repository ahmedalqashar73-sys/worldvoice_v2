import { readFile } from 'node:fs/promises';
import { before, beforeEach, after, test } from 'node:test';
import { strict as assert } from 'node:assert';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, query, setDoc, where, addDoc } from 'firebase/firestore';

let env;
const as = (uid) => env.authenticatedContext(uid).firestore();
const root = 'live_sessions/live_gift_test';

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-worldvoice-live-gifts',
    firestore: { rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, root), {
      channelId: 'live_gift_test',
      hostId: 'host',
      isLive: true,
      viewerCount: 1,
      guestCount: 1,
    });
    await setDoc(doc(db, root + '/viewers/viewer'), {
      uid: 'viewer', displayName: 'Watching',
    });
    await setDoc(doc(db, root + '/join_requests/guest'), {
      uid: 'guest', displayName: 'On camera', status: 'accepted',
    });
    await setDoc(doc(db, root + '/join_requests/applicant'), {
      uid: 'applicant', displayName: 'Waiting', status: 'pending',
    });
  });
});

after(async () => { await env?.cleanup(); });

test('joined viewers can list accepted on-camera recipients for live gifts', async () => {
  const db = as('viewer');
  const guests = query(collection(db, root + '/join_requests'),
    where('status', '==', 'accepted'));
  const snapshot = await assertSucceeds(getDocs(guests));
  assert.equal(snapshot.docs.length, 1);
  assert.equal(snapshot.docs[0].id, 'guest');
  await assertSucceeds(getDoc(doc(db, root + '/join_requests/guest')));
});

test('gift picker cannot reveal pending applications to a regular viewer', async () => {
  const db = as('viewer');
  await assertFails(getDocs(collection(db, root + '/join_requests')));
  await assertFails(getDocs(query(collection(db, root + '/join_requests'),
    where('status', '==', 'pending'))));
  await assertFails(getDoc(doc(db, root + '/join_requests/applicant')));
  await assertSucceeds(getDoc(doc(as('applicant'), root + '/join_requests/applicant')));
  const hostRequests = await assertSucceeds(getDocs(collection(as('host'), root + '/join_requests')));
  assert.equal(hostRequests.size, 2);
});

test('non-participants cannot enumerate on-camera guests or forge gift events', async () => {
  await assertFails(getDocs(query(collection(as('outsider'), root + '/join_requests'),
    where('status', '==', 'accepted'))));
  await assertFails(getDocs(query(collection(env.unauthenticatedContext().firestore(),
    root + '/join_requests'), where('status', '==', 'accepted'))));
  await assertFails(addDoc(collection(as('viewer'), root + '/gifts'), {
    senderId: 'viewer', recipientId: 'host',
    giftId: 'wv_gift_001', points: 500,
  }));
});
