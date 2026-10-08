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
