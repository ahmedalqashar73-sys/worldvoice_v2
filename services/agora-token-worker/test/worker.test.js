import assert from "node:assert/strict";
import test from "node:test";
import worker, { validChannelName, agoraUidForFirebaseUid } from "../src/index.js";

test("reject invalid room IDs before Firebase/Firestore", () => {
  assert.equal(validChannelName("good_room_123"), true);
  for (const value of ["", "room-with-dash", "../rooms/admin", "a".repeat(64), null]) {
    assert.equal(validChannelName(value), false);
  }
});

test("Agora UID is positive and deterministic", () => {
  assert.equal(agoraUidForFirebaseUid("uid_1"), agoraUidForFirebaseUid("uid_1"));
  assert.ok(agoraUidForFirebaseUid("uid_1") > 0);
});

test("health fails closed without the secret certificate", async () => {
  const response = await worker.fetch(new Request("https://test.example/health"), {
    FIREBASE_PROJECT_ID: "worldvoice-37896",
    AGORA_APP_ID: "fa41476c6813471eb45c059bcb4a0e19",
  });
  assert.equal(response.status, 503);
  assert.equal((await response.json()).ok, false);
});

test("POST token rejects missing bearer header", async () => {
  const response = await worker.fetch(
    new Request("https://test.example/agora/token", { method: "POST" }),
    {
      FIREBASE_PROJECT_ID: "worldvoice-37896",
      AGORA_APP_ID: "fa41476c6813471eb45c059bcb4a0e19",
      AGORA_APP_CERTIFICATE: "test-only-placeholder",
    },
  );
  assert.equal(response.status, 401);
});

test("nonexistent path rejects requests", async () => {
  const response = await worker.fetch(
    new Request("https://test.example/teacher-ai", { method: "POST" }),
    {},
  );
  assert.equal(response.status, 404);
});
