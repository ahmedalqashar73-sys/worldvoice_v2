import {readFile} from "node:fs/promises";
import {before, beforeEach, after, test} from "node:test";
import {initializeTestEnvironment, assertSucceeds, assertFails} from
  "@firebase/rules-unit-testing";
import {doc, getDoc, setDoc, updateDoc, getDocs, collection} from
  "firebase/firestore";

let env;
const dbFor = uid => env.authenticatedContext(uid).firestore();
const callDoc = db => doc(db, "calls/call123");

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-worldvoice-rules",
    firestore: {
      rules: await readFile(
        new URL("../../firestore.rules", import.meta.url), "utf8",
      ),
    },
  });
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx => {
    await setDoc(callDoc(ctx.firestore()), {
      callerId: "alice",
      recipientId: "bob",
      channelId: "call_call123",
      status: "ringing",
      type: "audio",
    });
  });
});
after(async () => { await env?.cleanup(); });

test("only verified call participants may read ringing or accepted calls", async () => {
  await assertSucceeds(getDoc(callDoc(dbFor("alice"))));
  await assertSucceeds(getDoc(callDoc(dbFor("bob"))));
  await assertFails(getDoc(callDoc(dbFor("intruder"))));
  await env.withSecurityRulesDisabled(async ctx => {
    await updateDoc(callDoc(ctx.firestore()), {status: "accepted"});
  });
  await assertSucceeds(getDoc(callDoc(dbFor("bob"))));
});

test("a participant cannot rewrite the call or list unrelated calls", async () => {
  await assertFails(updateDoc(callDoc(dbFor("alice")), {
    recipientId: "intruder",
  }));
  await assertFails(setDoc(callDoc(dbFor("bob")), {
    callerId: "bob", recipientId: "intruder", status: "accepted",
  }));
  await assertFails(getDocs(collection(dbFor("alice"), "calls")));
});

test("ended, declined, or missing calls cannot reveal token metadata", async () => {
  for (const status of ["ended", "declined"]) {
    await env.withSecurityRulesDisabled(async ctx => {
      await updateDoc(callDoc(ctx.firestore()), {status});
    });
    await assertFails(getDoc(callDoc(dbFor("alice"))));
    await assertFails(getDoc(callDoc(dbFor("bob"))));
  }
});
