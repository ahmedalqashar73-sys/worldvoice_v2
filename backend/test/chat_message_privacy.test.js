import test from "node:test";
import assert from "node:assert/strict";
import {canReceiveDirectMessages} from "../src/chat_routes.js";

test("direct messages are accepted by default for existing accounts", () => {
  assert.equal(canReceiveDirectMessages(undefined), true);
  assert.equal(canReceiveDirectMessages({}), true);
  assert.equal(canReceiveDirectMessages({receiveDirectMessages:true}), true);
});
test("privacy setting blocks new direct messages", () => {
  assert.equal(canReceiveDirectMessages({receiveDirectMessages:false}), false);
});
