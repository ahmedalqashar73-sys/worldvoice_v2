import {readFile} from 'node:fs/promises';
import {before, beforeEach, after, test} from 'node:test';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, setDoc, addDoc, collection, serverTimestamp, getDocs, updateDoc} from 'firebase/firestore';

let env;
const user = uid => env.authenticatedContext(uid).firestore();
const messages = db => collection(db, 'live_sessions/live_test/messages');

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-worldvoice-live-rules',
    firestore: {rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8')},
  });
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(doc(db, 'live_sessions/live_test'), {
      channelId: 'live_test', hostId: 'host', hostAgoraUid: 12345,
      isLive: true, viewerCount: 1, guestCount: 0, topic: '',
    });
    await setDoc(doc(db, 'live_sessions/live_test/viewers/guest'), {
      uid: 'guest', joinedAt: serverTimestamp(),
    });
  });
});
after(async () => { await env?.cleanup(); });

test('the Live viewer and host may send comments with safe custom bubbles', async () => {
  for (const uid of ['guest', 'host']) {
    const result = await assertSucceeds(addDoc(messages(user(uid)), {
      senderId: uid, senderName: uid,
      senderPhotoUrl: '',
      bubbleId: 'free', text: 'Hello WorldVoice Live!',
      createdAt: serverTimestamp(),
    }));
    await assertSucceeds(getDocs(messages(user(uid))));
    await assertFails(updateDoc(result, {text: 'spoof edit'}));
  }
});

test('the viewer join event has its own narrow validated shape', async () => {
  await assertSucceeds(addDoc(messages(user('guest')), {
    type: 'join', senderId: 'guest', senderName: 'Guest',
    senderPhotoUrl: '', text: '', createdAt: serverTimestamp(),
  }));
  await assertFails(addDoc(messages(user('stranger')), {
    type: 'join', senderId: 'stranger', senderName: 'Stranger',
    senderPhotoUrl: '', text: '', createdAt: serverTimestamp(),
  }));
});

test('Live chat rejects impersonation, arbitrary fields and forged timestamps', async () => {
  const message = {
    senderId: 'host', senderName: 'Host', senderPhotoUrl: '',
    text: 'hello', createdAt: serverTimestamp(), bubbleId: 'free',
  };
  await assertFails(addDoc(messages(user('guest')), message));
  await assertFails(addDoc(messages(user('host')), {...message, coins: 99999}));
  await assertFails(addDoc(messages(user('host')), {...message, text: ''}));
  await assertFails(addDoc(messages(user('host')), {...message, bubbleId: 'x'.repeat(100)}));
  await assertFails(addDoc(messages(user('host')), {...message, createdAt: new Date('2020-01-01')}));
});
