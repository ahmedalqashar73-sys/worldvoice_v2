import test from "node:test";
import assert from "node:assert/strict";
import {validateBetaContextMembership} from "../src/owner_beta_context_gifts.js";

const yes = value => ({exists: true, data: () => value});
test("room gifts require both participants and an open room", () => {
  const input = {context: "room", session: {isOpen: true},
    senderId: "a", recipientId: "b",
    senderMember: yes({}), recipientMember: yes({})};
  assert.equal(validateBetaContextMembership(input), true);
  assert.equal(validateBetaContextMembership({...input,
    recipientMember: {exists: false}}), false);
  assert.equal(validateBetaContextMembership({...input,
    session: {isOpen: false}}), false);
});
test("live gifts require active authenticated host/guest or viewer", () => {
  const now = Date.now();
  const input = {context: "live", now, senderId: "host", recipientId: "guest",
    session: {isLive: true, hostId: "host",
      hostHeartbeatAt: {toMillis: () => now - 1000}},
    senderMember: {exists: false},
    recipientMember: yes({uid: "guest", status: "accepted"})};
  assert.equal(validateBetaContextMembership(input), true);
  assert.equal(validateBetaContextMembership({...input,
    recipientMember: yes({uid: "guest", status: "pending"})}), false);
  assert.equal(validateBetaContextMembership({...input,
    session: {...input.session,
      hostHeartbeatAt: {toMillis: () => now - 70_000}}}), false);
});
