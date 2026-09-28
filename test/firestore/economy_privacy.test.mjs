import {readFile} from "node:fs/promises";
import {before, beforeEach, after, test} from "node:test";
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from "@firebase/rules-unit-testing";
import {doc, setDoc, getDoc, updateDoc, deleteDoc} from "firebase/firestore";

let env;
const dbFor = uid => env.authenticatedContext(uid).firestore();

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
    const admin = context.firestore();
    await setDoc(doc(admin, "users/alice"), {
      uid: "alice", displayName: "Alice",
      // Staged legacy field; cleanup is a separate release gate.
      coins: 10,
    });
    await setDoc(doc(admin, "users/alice/private/wallet"), {
      coins: 10, diamonds: 3, walletFrozen: false,
    });
    await setDoc(doc(admin, "public_profiles/alice"), {
      uid: "alice", displayName: "Alice",
    });
  });
});
after(async () => {await env?.cleanup();});

test("only the account owner can read the new private wallet", async () => {
  await assertSucceeds(getDoc(doc(dbFor("alice"), "users/alice/private/wallet")));
  await assertFails(getDoc(doc(dbFor("bob"), "users/alice/private/wallet")));
  await assertFails(getDoc(doc(dbFor("bob"), "users/alice/wallet_transactions/tx1")));
});

test("only trusted backend may create or change money documents", async () => {
  const ownWallet = doc(dbFor("alice"), "users/alice/private/wallet");
  await assertFails(updateDoc(ownWallet, {coins: 100000}));
  await assertFails(deleteDoc(ownWallet));
  await assertFails(setDoc(doc(dbFor("bob"), "users/bob/private/wallet"), {
    coins: 999999,
  }));
});

test("signed-in peers can read sanitized public projection, not write it", async () => {
  const projection = doc(dbFor("bob"), "public_profiles/alice");
  await assertSucceeds(getDoc(projection));
  await assertFails(updateDoc(projection, {coins: 999999}));
});
