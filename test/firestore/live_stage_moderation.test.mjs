import {readFile} from 'node:fs/promises';
import {before, beforeEach, after, test} from 'node:test';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, setDoc, updateDoc, writeBatch, serverTimestamp, increment, deleteField} from 'firebase/firestore';

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

test('only the host may mute and release a current Live stage guest', async () => {
  await assertSucceeds(updateDoc(guestRequest(user('host')), {hostMuted: true}));
  await assertSucceeds(updateDoc(guestRequest(user('host')), {hostMuted: false}));
  await assertFails(updateDoc(guestRequest(user('guest')), {hostMuted: false}));
  await assertFails(updateDoc(guestRequest(user('stranger')), {hostMuted: true}));
});

test('host microphone control cannot forge guest identity or stage status', async () => {
  await assertFails(updateDoc(guestRequest(user('host')), {
    hostMuted: true, displayName: 'forged',
  }));
  await assertFails(updateDoc(guestRequest(user('host')), {
    hostMuted: true, status: 'removed',
  }));
});

const setupPendingStageRequest = async () => {
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(live(db), {
      channelId: 'live_stage_test', hostId: 'host', hostAgoraUid: 9876,
      isLive: true, isReady: true, viewerCount: 1, guestCount: 0,
      topic: 'English',
    });
    await setDoc(doc(db, 'live_sessions/live_stage_test/viewers/guest'), {
      uid: 'guest', displayName: 'Guest', photoUrl: '', joinedAt: serverTimestamp(),
    });
    await setDoc(guestRequest(db), {
      uid: 'guest', displayName: 'Guest', photoUrl: '', status: 'pending',
      requestedAt: serverTimestamp(), hostMuted: false,
    });
  });
};

const invitePending = db => updateDoc(guestRequest(db), {
  status: 'invited',
  invitedBy: 'host',
  invitedAt: serverTimestamp(),
  requestedAt: deleteField(),
  hostMuted: false,
});

test('host approval sends an invitation; guest must accept before a seat is counted', async () => {
  await setupPendingStageRequest();
  await assertSucceeds(invitePending(user('host')));
  const guestDb = user('guest');
  const batch = writeBatch(guestDb);
  batch.update(guestRequest(guestDb), {
    status: 'accepted', decidedAt: serverTimestamp(),
  });
  batch.update(live(guestDb), {
    guestCount: increment(1), updatedAt: serverTimestamp(),
  });
  await assertSucceeds(batch.commit());
});

test('host cannot directly accept a pending guest without consent', async () => {
  await setupPendingStageRequest();
  await assertFails(updateDoc(guestRequest(user('host')), {
    status: 'accepted', decidedAt: serverTimestamp(),
  }));
});

test('a random viewer cannot turn a pending request into a host invitation', async () => {
  await setupPendingStageRequest();
  await assertFails(invitePending(user('stranger')));
});

test('guest must not accept an invitation without atomically claiming capacity', async () => {
  await setupPendingStageRequest();
  await assertSucceeds(invitePending(user('host')));
  await assertFails(updateDoc(guestRequest(user('guest')), {
    status: 'accepted', decidedAt: serverTimestamp(),
  }));
});

test('a live cannot exceed three guest seats even when invitation exists', async () => {
  await setupPendingStageRequest();
  await assertSucceeds(invitePending(user('host')));
  await env.withSecurityRulesDisabled(async context => {
    await updateDoc(live(context.firestore()), {guestCount: 3});
  });
  const db = user('guest');
  const batch = writeBatch(db);
  batch.update(guestRequest(db), {
    status: 'accepted', decidedAt: serverTimestamp(),
  });
  batch.update(live(db), {
    guestCount: increment(1), updatedAt: serverTimestamp(),
  });
  await assertFails(batch.commit());
});

test('host cannot fabricate capacity and viewer cannot inflate it either', async () => {
  await assertFails(updateDoc(live(user('host')), {
    guestCount: increment(1), updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(live(user('stranger')), {
    guestCount: increment(1), updatedAt: serverTimestamp(),
  }));
});
