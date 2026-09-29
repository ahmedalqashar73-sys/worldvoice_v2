import { readFile } from 'node:fs/promises';
import { before, beforeEach, after, test } from 'node:test';
import { strict as assert } from 'node:assert';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, collection, getDoc, getDocs, setDoc, updateDoc, deleteDoc, writeBatch, serverTimestamp, increment, query, orderBy, limit } from 'firebase/firestore';

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

test('room tasks and level XP cannot be forged by host or listener', async () => {
  const hostDb = user('host');
  const listenerDb = user('listener');
  await assertFails(updateDoc(room(hostDb), {
    roomXp: 5900, roomLevel: 60,
  }));
  await assertFails(updateDoc(room(listenerDb), {
    roomXp: 500, roomLevel: 6,
  }));
  await assertFails(setDoc(doc(listenerDb, 'rooms/r1/task_completions/ten_minutes_listener_today'), {
    userId: 'listener', taskKey: 'ten_minutes', points: 4,
    periodKey: 'today', completedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(hostDb, 'rooms/r1/rewards/level_60'), {
    level: 60, type: 'gift_pack', unlockedBy: 'host',
  }));
  await assertFails(setDoc(doc(listenerDb, 'users/listener/room_rewards/r1_level_60'), {
    userId: 'listener', roomId: 'r1', level: 60,
    type: 'gift_pack', sourceRewardId: 'level_60',
  }));
});

test('new participant entry must use trusted server time', async () => {
  const db = user('new');
  const candidate = participant('new');
  await assertFails(setDoc(member(db, 'new'), {
    ...candidate, joinedAt: new Date('2020-01-01T00:00:00Z'),
    updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(setDoc(member(db, 'new'), {
    ...candidate, joinedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
});

test('signed-in room listing works and anonymous access is rejected', async () => {
  await assertSucceeds(getDocs(collection(user('new'), 'rooms')));
  await assertFails(getDocs(collection(env.unauthenticatedContext().firestore(), 'rooms')));
  for (const catalog of ['room_promotions', 'gift_level_thresholds', 'room_shop_items', 'room_gift_catalog']) {
    await assertSucceeds(getDocs(collection(user('new'), catalog)));
    await assertFails(setDoc(doc(user('new'), catalog + '/fake'), {active: true}));
  }
});

test('private wallet balances stay owner-only, even for signed-in strangers', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/listener/private/wallet'),
      {coins: 425, diamonds: 17, walletFrozen: false});
    await setDoc(doc(db, 'public_profiles/listener'),
      {uid: 'listener', displayName: 'Visible member'});
  });
  const owner = user('listener');
  const stranger = user('other');
  const privatePath = 'users/listener/private/wallet';
  const visible = await assertSucceeds(getDoc(doc(owner, privatePath)));
  assert.equal(visible.data().coins, 425);
  await assertFails(getDoc(doc(stranger, privatePath)));
  await assertFails(getDocs(collection(stranger, 'users/listener/private')));
  await assertFails(setDoc(doc(owner, privatePath), {coins: 999999}));
  await assertFails(updateDoc(doc(owner, privatePath), {diamonds: 999999}));
  await assertSucceeds(getDoc(doc(stranger, 'public_profiles/listener')));
  await assertFails(setDoc(doc(stranger, 'public_profiles/listener'),
    {coins: 9000000}));
});

test('economy reads are permitted but client-side money and gifts cannot be forged', async () => {
  const db = user('listener');
  for (const name of ['coin_products', 'economy_config', 'store_items']) {
    await assertSucceeds(getDocs(collection(db, name)));
    await assertFails(setDoc(doc(db, name + '/fake'), {active: true}));
  }
  const profile = doc(db, 'users/listener');
  await assertSucceeds(setDoc(profile, {uid: 'listener', displayName: 'Guest', coins: 0}));
  for (const field of ['coins', 'diamonds', 'diamondsPending', 'giftLevel']) {
    await assertFails(updateDoc(profile, {[field]: 1000000}));
  }
  await assertSucceeds(updateDoc(profile, {displayName: 'Guest 2'}));
  await assertFails(setDoc(doc(db, 'users/new'), {uid: 'new', coins: 500}));
  for (const profile of [
    {uid: 'fresh', coins: 500},
    {uid: 'fresh', diamonds: 1},
    {uid: 'fresh', walletFrozen: false},
    {uid: 'fresh', identityVerified: true},
    {uid: 'fresh', giftLevel: 99}
  ]) {
    await assertFails(setDoc(doc(user('fresh'), 'users/fresh'), profile));
  }
  await assertSucceeds(setDoc(doc(user('fresh'), 'users/fresh'),
    {uid: 'fresh', displayName: 'Fresh', coins: 0}));
  for (const field of ['walletFrozen', 'payoutFrozen', 'walletDebtCoins', 'identityVerified']) {
    await assertFails(updateDoc(doc(user('fresh'), 'users/fresh'), {[field]: 1}));
  }

  for (const name of ['inventory', 'wallet_transactions', 'diamond_lots', 'economy_daily']) {
    await assertFails(setDoc(doc(db, 'users/listener/' + name + '/fake'), {value: 100}));
  }
  await assertFails(setDoc(doc(db, 'rooms/r1/gifts/fake'), {
    senderId: 'listener', recipientId: 'host', giftId: 'rose',
    points: 10, createdAt: serverTimestamp()
  }));
  await assertFails(setDoc(doc(db, 'economy_gift_operations/fake'), {coins: 100}));
});

test('migrated wallets are owner-only and public profile projection is backend-only', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/listener/private/wallet'), {
      coins: 77, diamonds: 9,
    });
    await setDoc(doc(db, 'public_profiles/listener'), {
      uid: 'listener', displayName: 'Public Listener',
    });
  });
  await assertSucceeds(getDoc(doc(user('listener'),
    'users/listener/private/wallet')));
  await assertFails(getDoc(doc(user('other'),
    'users/listener/private/wallet')));
  await assertFails(setDoc(doc(user('listener'),
    'users/listener/private/wallet'), {coins: 9999}));
  await assertSucceeds(getDoc(doc(user('other'),
    'public_profiles/listener')));
  await assertFails(setDoc(doc(user('other'),
    'public_profiles/listener'), {coins: 9999}));
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

test('verified quiz answers are immutable, round-scoped, and secret stays private', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'rooms/r1/quiz_private/current'), {
      roundId: 'secure-round', correctIndex: 1,
    });
    await updateDoc(room(db), {
      quiz: {question: 'Question?', options: ['No', 'Yes'],
        roundId: 'secure-round', revealed: false, practiceOnly: true}
    });
  });
  const listenerDb = user('listener');
  const answerRef = doc(listenerDb, 'rooms/r1/quiz_answers/listener');
  const payload = {
    userId: 'listener', displayName: 'Listener', optionIndex: 1,
    roundId: 'secure-round', answeredAt: serverTimestamp(),
  };
  await assertFails(getDoc(doc(listenerDb, 'rooms/r1/quiz_private/current')));
  await assertFails(getDoc(doc(user('host'), 'rooms/r1/quiz_private/current')));
  await assertFails(setDoc(doc(user('host'), 'rooms/r1/quiz_private/current'),
    {roundId: 'hacked', correctIndex: 0}));
  await assertFails(setDoc(answerRef, {...payload, roundId: 'previous'}));
  await assertFails(setDoc(answerRef, {...payload, optionIndex: 999}));
  await assertSucceeds(setDoc(answerRef, payload));
  await assertFails(updateDoc(answerRef, {optionIndex: 0}));
  await assertFails(deleteDoc(answerRef));
  await assertFails(deleteDoc(doc(user('host'), 'rooms/r1/quiz_answers/listener')));
});

test('AI notes are readable by members but only the backend may write', async () => {
  await assertSucceeds(getDocs(collection(user('listener'), 'rooms/r1/teacher_ai_notes')));
  await assertFails(getDocs(collection(user('outsider'), 'rooms/r1/teacher_ai_notes')));
  await assertFails(setDoc(doc(user('host'), 'rooms/r1/teacher_ai_notes/fake'), {text: 'fake'}));
});

test('live captions query allows room members and denies non-members', async () => {
  const captions = 'rooms/r1/captions';
  const payload = {
    userId: 'host', displayName: 'Host', text: 'Testing captions',
    languageCode: 'en', createdAt: serverTimestamp()
  };
  // A room's host can publish while a listener can read, as the Flutter
  // UI queries captions ordered by createdAt descending with a limit.
  await assertSucceeds(setDoc(doc(user('host'), captions + '/c1'), payload));
  const watchQuery = (uid) =>
    query(collection(user(uid), captions), orderBy('createdAt', 'desc'), limit(30));
  const listenerRead = await assertSucceeds(getDocs(watchQuery('listener')));
  assert.equal(listenerRead.size, 1);
  await assertFails(getDocs(watchQuery('outsider')));
  await assertFails(setDoc(doc(user('outsider'), captions + '/c2'),
    {...payload, userId: 'outsider'}));
  await assertFails(setDoc(doc(user('listener'), captions + '/c3'),
    {...payload, userId: 'listener'}));
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
