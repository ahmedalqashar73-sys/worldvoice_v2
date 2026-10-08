import test from "node:test";
import assert from "node:assert/strict";
import {chatIdFor, assertChatMembership} from "../src/chat_membership.js";

const a = "firebase_user_alice";
const b = "firebase_user_bobby";
test("deterministic chat ID is symmetric and unique across peers", () => {
  assert.match(chatIdFor(a, b), /^[a-f0-9]{64}$/);
  assert.equal(chatIdFor(a, b), chatIdFor(b, a));
  assert.notEqual(chatIdFor(a, b), chatIdFor(a, "firebase_user_clara"));
  assert.throws(() => chatIdFor(a, a));
  assert.throws(() => chatIdFor("bad/id", b));
});
test("two verified members required for chat gifts", () => {
  assert.equal(assertChatMembership({active: true, memberIds: [a, b]}, a, b), true);
  assert.throws(() =>
    assertChatMembership({active: false, memberIds: [a, b]}, a, b));
  assert.throws(() =>
    assertChatMembership({active: true, memberIds: [a, "thirdperson"]}, a, b));
  assert.throws(() =>
    assertChatMembership({active: true, memberIds: [a, b, "extra"]}, a, b));
});
