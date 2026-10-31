import test from "node:test";
import assert from "node:assert/strict";
import {validChatMessageId} from "../src/chat_routes.js";

test("Firestore generated group chat identifiers can send text", () => {
  assert.equal(validChatMessageId("Yx6yHNCnWoQwYBvqXw5K"), true);
  assert.equal(validChatMessageId("group-chat_1234567890"), true);
});

test("existing hashed direct conversation identifiers still work", () => {
  assert.equal(validChatMessageId("a".repeat(64)), true);
});

test("malformed chat ids do not reach Firestore", () => {
  for (const value of ["", "short", "../users/a", "a/b/c", "space id", "a".repeat(161)]) {
    assert.equal(validChatMessageId(value), false, value);
  }
});
