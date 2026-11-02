import test from "node:test";
import assert from "node:assert/strict";
import {validateLiveGiftMembership} from "../src/gift_send_routes.js";

const snap = (uid, extra = {}) => ({
  exists: true,
  data: () => ({uid, ...extra}),
});
const now = 1_800_000_000_000;
const live = {
  hostId: "host", isLive: true, channelId: "room-live-1",
  hostHeartbeatAt: {toMillis: () => now - 1500},
};
const base = {
  live, contextId: "room-live-1", now, senderId: "host",
  recipientId: "viewer", senderMember: {exists: false},
  recipientGuest: {exists: false}, recipientViewer: snap("viewer"),
};

test("live audience viewer can receive paid gift from the host", () => {
  assert.equal(validateLiveGiftMembership(base), true);
});
test("authenticated audience viewer may gift another audience viewer", () => {
  const input = {...base, senderId: "sender", senderMember: snap("sender")};
  assert.equal(validateLiveGiftMembership(input), true);
});
test("host and accepted guest remain eligible recipients", () => {
  assert.equal(validateLiveGiftMembership({
    ...base, recipientId: "host", senderId: "viewer",
    senderMember: snap("viewer"), recipientViewer: {exists: false},
  }), true);
  assert.equal(validateLiveGiftMembership({
    ...base, recipientId: "guest", recipientViewer: {exists: false},
    recipientGuest: snap("guest", {status: "accepted"}),
  }), true);
});
test("reject spoofed, absent, pending and ended live membership", () => {
  assert.equal(validateLiveGiftMembership({
    ...base, recipientViewer: snap("other"),
  }), false);
  assert.equal(validateLiveGiftMembership({
    ...base, recipientViewer: {exists: false},
  }), false);
  assert.equal(validateLiveGiftMembership({
    ...base, recipientGuest: snap("viewer", {status: "pending"}),
    recipientViewer: {exists: false},
  }), false);
  assert.equal(validateLiveGiftMembership({
    ...base, senderId: "other", senderMember: snap("viewer"),
  }), false);
  assert.equal(validateLiveGiftMembership({
    ...base, live: {...live, channelId: "another-live"},
  }), false);
  assert.equal(validateLiveGiftMembership({
    ...base, live: {...live, hostHeartbeatAt: {toMillis: () => now - 61_000}},
  }), false);
  assert.equal(validateLiveGiftMembership({
    ...base, live: {...live, isLive: false},
  }), false);
});
