import test from "node:test";
import assert from "node:assert/strict";
import {registerRoomChatNotificationRoutes}
  from "../src/room_chat_notification_routes.js";

test("room comment route never sends FCM or looks up participants", async () => {
  let handler;
  const app = {
    post(path, callback) {
      assert.equal(path, "/system/room-message/notify");
      handler = callback;
    },
  };
  const db = new Proxy({}, {get() {
    throw new Error("Room comments must not query recipients or send push");
  }});
  registerRoomChatNotificationRoutes({
    app, db,
    authenticatedUser: async () => ({uid: "sender"}),
  });
  assert.equal(typeof handler, "function");
  let body;
  await handler({body: {roomId: "room_12345", messageId: "message_12345"}},
    {json(value) {body = value;}}, (error) => {throw error;});
  assert.deepEqual(body, {ok: true, disabled: true, receivers: 0});
});

test("room comment route does not bypass authentication", async () => {
  let handler;
  registerRoomChatNotificationRoutes({
    app: {post(_path, callback) {handler = callback;}},
    authenticatedUser: async () => {throw new Error("unauthorized");},
  });
  let nextError;
  await handler({}, {json() {throw new Error("must not respond");}},
    (error) => {nextError = error;});
  assert.equal(nextError.message, "unauthorized");
});
