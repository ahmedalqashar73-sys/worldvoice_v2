import {readFile} from "node:fs/promises";
import {before, beforeEach, after, test} from "node:test";
import {initializeTestEnvironment, assertSucceeds, assertFails} from
  "@firebase/rules-unit-testing";
import {doc, collection, setDoc, getDoc, getDocs, query, where, addDoc,
  serverTimestamp} from "firebase/firestore";

let env;
const dbFor = uid => env.authenticatedContext(uid).firestore();
const chat = db => doc(db, "chats/chat001");
const messages = db => collection(db, "chats/chat001/messages");

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-worldvoice-rules",
    firestore: {
      rules: await readFile(new URL("../../firestore.rules", import.meta.url), "utf8"),
    },
  });
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(chat(context.firestore()), {
      memberIds: ["alice", "bob"], memberNames: {alice: "Alice", bob: "Bob"},
      active: true,
    });
    await setDoc(doc(context.firestore(), "chats/chat001/messages/m1"), {
      type: "gift", senderId: "alice", recipientId: "bob",
      giftId: "rose", points: 1,
    });
  });
});
after(async () => { await env?.cleanup(); });

test("only verified chat participants can read conversation and gift event", async () => {
  await assertSucceeds(getDoc(chat(dbFor("alice"))));
  await assertSucceeds(getDocs(
    query(collection(dbFor("bob"), "chats"),
      where("memberIds", "array-contains", "bob"),
      where("active", "==", true))));
  await assertSucceeds(getDocs(messages(dbFor("bob"))));
  await assertFails(getDoc(chat(dbFor("stranger"))));
  await assertFails(getDocs(messages(dbFor("stranger"))));
});

test("a client cannot mint fake gift, overwrite participants or insert text", async () => {
  await assertFails(addDoc(messages(dbFor("bob")), {
    type: "gift", senderId: "bob", recipientId: "alice", points: 999999,
  }));
  await assertFails(addDoc(messages(dbFor("alice")), {
    type: "text", senderId: "alice", text: "hello",
  }));
  await assertFails(setDoc(chat(dbFor("alice")), {
    memberIds: ["alice", "stranger"], active: true,
  }));
});


test('chat member demos cannot impersonate others, charge coins or write messages', async () => {
  const alice = dbFor('alice');
  const bob = dbFor('bob');
  const preview = doc(alice, 'chats/chat001/gift_previews/alice');
  const notice = {
    nonce: 'abcdefabcdefabcdefabcdef',
    senderId: 'alice',
    senderName: 'Alice',
    recipientId: 'bob',
    recipientName: 'Bob',
    giftId: 'wv_gift_002',
    sentAt: serverTimestamp(),
  };
  await assertSucceeds(setDoc(preview, notice));
  await assertSucceeds(getDocs(collection(
    bob, 'chats/chat001/gift_previews')));
  await assertFails(setDoc(preview, {...notice,
    nonce: '123456123456123456123456'})); // anti-spam cooldown
  await assertFails(setDoc(doc(dbFor('stranger'),
    'chats/chat001/gift_previews/stranger'), {
    ...notice, senderId: 'stranger', senderName: 'Stranger',
  }));
  await assertFails(setDoc(doc(bob, 'chats/chat001/gift_previews/bob'), {
    ...notice, senderId: 'bob', senderName: 'Alice',
    recipientId: 'alice', recipientName: 'Alice',
  }));
  await assertFails(setDoc(doc(bob, 'chats/chat001/gift_previews/bob'), {
    ...notice, senderId: 'bob', senderName: 'Bob',
    recipientId: 'alice', recipientName: 'Alice', diamonds: 10000,
  }));
  await assertFails(addDoc(messages(alice), {
    type: 'gift', senderId: 'alice', giftId: 'wv_gift_001',
    points: 99999,
  }));
});

const delivery = db => doc(db, 'chats/chat001/delivery_queue/delivery001');
const chunk = db => doc(db, 'chats/chat001/delivery_queue/delivery001/delivery_chunks/0');
async function seedDeliveryKeys() {
  await env.withSecurityRulesDisabled(async ctx => {
    for (const uid of ['alice', 'bob']) await setDoc(doc(ctx.firestore(), `chat_delivery_keys/${uid}`), {
      publicKey: (uid === 'alice' ? 'A' : 'B').repeat(44),
    });
  });
}
function envelope() {
  return {senderId: 'alice', recipientId: 'bob', senderKey: 'A'.repeat(44),
    recipientKey: 'B'.repeat(44), state: 'uploading', chunkCount: 1,
    expiresAt: new Date(Date.now() + 7 * 86400000), updatedAt: serverTimestamp()};
}

test('encrypted delivery: sender upload, recipient cleanup, sender receipt', async () => {
  const {updateDoc, deleteDoc} = await import('firebase/firestore');
  await seedDeliveryKeys();
  const data = envelope();
  await assertSucceeds(setDoc(delivery(dbFor('alice')), data));
  await assertSucceeds(setDoc(chunk(dbFor('alice')), {
    cipher: 'encrypted', nonce: 'N'.repeat(16), mac: 'M'.repeat(24), expiresAt: data.expiresAt,
  }));
  await assertFails(getDoc(delivery(dbFor('stranger'))));
  await assertFails(getDoc(chunk(dbFor('stranger'))));
  await assertFails(updateDoc(delivery(dbFor('alice')), {state: 'received', updatedAt: serverTimestamp()}));
  await assertFails(deleteDoc(chunk(dbFor('alice'))));
  await assertSucceeds(updateDoc(delivery(dbFor('alice')), {state: 'ready', updatedAt: serverTimestamp()}));
  await assertSucceeds(getDocs(collection(dbFor('bob'), 'chats/chat001/delivery_queue')));
  await assertSucceeds(getDoc(chunk(dbFor('bob'))));
  await assertFails(updateDoc(chunk(dbFor('alice')), {cipher: 'changed after ready'}));
  await assertFails(updateDoc(delivery(dbFor('bob')), {recipientId: 'stranger'}));
  await assertSucceeds(deleteDoc(chunk(dbFor('bob'))));
  await assertSucceeds(updateDoc(delivery(dbFor('bob')), {state: 'received', updatedAt: serverTimestamp()}));
  await assertSucceeds(deleteDoc(delivery(dbFor('alice'))));
});

test('delivery rejects plaintext, impersonation, oversized chunks and blocked senders', async () => {
  await seedDeliveryKeys();
  const data = envelope();
  await assertFails(setDoc(delivery(dbFor('bob')), data));
  await assertFails(setDoc(delivery(dbFor('alice')), {...data, text: 'private'}));
  await assertFails(setDoc(delivery(dbFor('alice')), {...data, recipientId: 'stranger'}));
  await assertFails(setDoc(delivery(dbFor('alice')), {...data, chunkCount: 642}));
  await assertFails(setDoc(delivery(dbFor('alice')), {...data, senderKey: 'forged'}));
  await assertSucceeds(setDoc(delivery(dbFor('alice')), data));
  const bytes = {cipher: 'abc', nonce: 'N'.repeat(16), mac: 'M'.repeat(24), expiresAt: data.expiresAt};
  await assertFails(setDoc(chunk(dbFor('bob')), bytes));
  await assertFails(setDoc(chunk(dbFor('alice')), {...bytes, fileName: 'private.jpg'}));
  await assertFails(setDoc(chunk(dbFor('alice')), {...bytes, cipher: 'A'.repeat(175001)}));
  await assertFails(setDoc(doc(dbFor('alice'), 'chats/chat001/delivery_queue/delivery001/delivery_chunks/1'), bytes));
  await env.withSecurityRulesDisabled(async ctx => {
    await setDoc(doc(ctx.firestore(), 'users/bob/blocked_peers/alice'), {blocked: true});
  });
  await assertFails(setDoc(chunk(dbFor('alice')), bytes));
  await assertFails(setDoc(doc(dbFor('alice'), 'chats/chat001/delivery_queue/newDelivery'), data));
});

test('delivery identity is public but cannot be overwritten by another account', async () => {
  const key = {publicKey: 'A'.repeat(44), updatedAt: serverTimestamp()};
  await assertSucceeds(setDoc(doc(dbFor('alice'), 'chat_delivery_keys/alice'), key));
  await assertSucceeds(getDoc(doc(dbFor('bob'), 'chat_delivery_keys/alice')));
  await assertFails(setDoc(doc(dbFor('bob'), 'chat_delivery_keys/alice'), key));
  await assertFails(setDoc(doc(dbFor('alice'), 'chat_delivery_keys/alice'), {...key, privateKey: 'secret'}));
});

test('group call tokens: current members may read, outsiders cannot impersonate', async () => {
  const path = 'group_calls/chat001';
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(chat(context.firestore()), {
      memberIds: ['alice', 'bob', 'charlie'],
      memberNames: {alice: 'Alice', bob: 'Bob', charlie: 'Charlie'},
      active: true, type: 'group',
    });
    await setDoc(doc(context.firestore(), path), {
      chatId: 'chat001',
      channelId: 'group_chat001',
      type: 'video',
      status: 'active',
      ownerId: 'alice',
      memberIds: ['alice', 'bob', 'charlie'],
      joinedIds: ['alice', 'bob'],
    });
  });
  await assertSucceeds(getDoc(doc(dbFor('alice'), path)));
  await assertSucceeds(getDoc(doc(dbFor('bob'), path)));
  await assertFails(getDoc(doc(dbFor('stranger'), path)));
  await assertFails(getDocs(collection(dbFor('alice'), 'group_calls')));
  await assertFails(setDoc(doc(dbFor('alice'), path), {
    status: 'active', joinedIds: ['stranger'],
  }));
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(chat(context.firestore()), {
      memberIds: ['alice', 'charlie'],
      memberNames: {alice: 'Alice', charlie: 'Charlie'},
      active: true, type: 'group',
    });
  });
  await assertFails(getDoc(doc(dbFor('bob'), path)));
});
