import { readFile } from 'node:fs/promises';
import { before, beforeEach, after, test } from 'node:test';
import { strict as assert } from 'node:assert';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, collection, getDoc, getDocs, setDoc, updateDoc, deleteDoc, writeBatch, serverTimestamp, increment } from 'firebase/firestore';

let env;
const user = (uid) => env.authenticatedContext(uid).firestore();
const room = (db) => doc(db, 'rooms/r1');
const member = (db, uid) => doc(db, 'rooms/r1/participants/' + uid);
const participant = (uid, host = false) => ({
  uid, displayName: uid, role: host ? 'host' : 'listener',
  ...(host ? {seatIndex: 1} : {}),
  handRaised: false, isModerator: false, warningCount: 0,
  forcedMuted: false, kicked: false
});
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-worldvoice-rules',
    firestore: {rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8')}
  });
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(room(db), {
      channelId: 'r1', hostId: 'host', isOpen: true, isPrivate: false,
      boardWriteEnabled: true, themeId: 'royalPurple',
      quiz: {question: '2 + 2?', options: ['3', '4'], correctIndex: 1, revealed: false}
    });
    await setDoc(member(db, 'host'), participant('host', true));
    await setDoc(member(db, 'listener'), participant('listener'));
  });
});
after(async () => { await env?.cleanup(); });

test('quota and history are available only to their owner before joining', async () => {
  const db = user('new');
  const usage = doc(db, 'users/new/room_usage/20260924');
  await assertSucceeds(getDoc(usage));
  await assertSucceeds(setDoc(usage, {usedSeconds: 60, updatedAt: serverTimestamp()}));
  await assertSucceeds(updateDoc(usage, {usedSeconds: increment(60)}));
  await assertFails(updateDoc(usage, {usedSeconds: 0}));
  const history = doc(db, 'users/new/room_history/r1');
  await assertSucceeds(setDoc(history, {roomId: 'r1', visitCount: 1}));
  await assertSucceeds(getDocs(collection(db, 'users/new/room_history')));
  await assertFails(getDoc(doc(user('other'), 'users/new/room_usage/20260924')));
  await assertFails(setDoc(doc(user('other'), 'users/new/room_history/r1'), {roomId: 'r1'}));
});

test('signed-in room listing works and anonymous access is rejected', async () => {
  await assertSucceeds(getDocs(collection(user('new'), 'rooms')));
  await assertFails(getDocs(collection(env.unauthenticatedContext().firestore(), 'rooms')));
  for (const catalog of ['room_promotions', 'gift_level_thresholds', 'room_shop_items', 'room_gift_catalog']) {
    await assertSucceeds(getDocs(collection(user('new'), catalog)));
    await assertFails(setDoc(doc(user('new'), catalog + '/fake'), {active: true}));
  }
});

test('host creates room and participant atomically; listener cannot self-promote', async () => {
  const db = user('new');
  const batch = writeBatch(db);
  batch.set(doc(db, 'rooms/newroom'), {channelId: 'newroom', hostId: 'new', isOpen: true, isPrivate: false});
  batch.set(doc(db, 'rooms/newroom/participants/new'), participant('new', true));
  await assertSucceeds(batch.commit());
  await assertSucceeds(setDoc(member(user('new'), 'new'), participant('new')));
  await assertFails(updateDoc(member(user('new'), 'new'), {role: 'host', seatIndex: 1}));
  await assertSucceeds(updateDoc(member(user('new'), 'new'), {handRaised: true, requestedSeatIndex: 2}));
});

test('chat is restricted to members and cannot impersonate another user', async () => {
  const payload = {userId: 'listener', text: 'Hello', createdAt: serverTimestamp()};
  await assertSucceeds(setDoc(doc(user('listener'), 'rooms/r1/messages/m1'), payload));
  await assertFails(setDoc(doc(user('listener'), 'rooms/r1/messages/m2'), {...payload, userId: 'host'}));
  await assertFails(getDocs(collection(user('outsider'), 'rooms/r1/messages')));
});

test('lesson board is writable by host; participants can write when enabled', async () => {
  const text = {userId: 'listener', type: 'text', text: 'Hello', createdAt: serverTimestamp()};
  await assertSucceeds(setDoc(doc(user('listener'), 'rooms/r1/board_items/a'), text));
  await assertSucceeds(updateDoc(room(user('host')), {boardWriteEnabled: false}));
  await assertFails(setDoc(doc(user('listener'), 'rooms/r1/board_items/b'), text));
  await assertSucceeds(setDoc(doc(user('host'), 'rooms/r1/board_items/c'), {...text, userId: 'host'}));
  await assertFails(getDocs(collection(user('outsider'), 'rooms/r1/board_items')));
});

test('quiz accepts member answers, host reveals, and late answers are denied', async () => {
  const answer = {userId: 'listener', optionIndex: 1, displayName: 'Listener', answeredAt: serverTimestamp()};
  await assertSucceeds(setDoc(doc(user('listener'), 'rooms/r1/quiz_answers/listener'), answer));
  await assertFails(setDoc(doc(user('outsider'), 'rooms/r1/quiz_answers/outsider'), {...answer, userId: 'outsider'}));
  await assertFails(updateDoc(room(user('listener')), {'quiz.revealed': true}));
  await assertSucceeds(updateDoc(room(user('host')), {'quiz.revealed': true}));
  assert.equal((await getDoc(room(user('host')))).data().quiz.revealed, true);
  await assertFails(setDoc(doc(user('listener'), 'rooms/r1/quiz_answers/listener'), answer));
  await assertSucceeds(deleteDoc(doc(user('host'), 'rooms/r1/quiz_answers/listener')));
});

test('AI notes are readable by members but only the backend may write', async () => {
  await assertSucceeds(getDocs(collection(user('listener'), 'rooms/r1/teacher_ai_notes')));
  await assertFails(getDocs(collection(user('outsider'), 'rooms/r1/teacher_ai_notes')));
  await assertFails(setDoc(doc(user('host'), 'rooms/r1/teacher_ai_notes/fake'), {text: 'fake'}));
});

test('private room join requires a matching code grant', async () => {
  await assertSucceeds(updateDoc(room(user('host')), {isPrivate: true}));
  const db = user('new');
  await assertFails(setDoc(member(db, 'new'), participant('new')));
  await assertSucceeds(setDoc(doc(user('host'), 'private_room_codes/ABC123'), {hostId: 'host', roomId: 'r1'}));
  await assertFails(getDocs(collection(db, 'private_room_codes')));
  await assertSucceeds(setDoc(doc(db, 'rooms/r1/access_grants/new'), {uid: 'new', code: 'ABC123'}));
  await assertSucceeds(setDoc(member(db, 'new'), participant('new')));
});
