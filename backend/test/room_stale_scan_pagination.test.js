import test from "node:test";
import assert from "node:assert/strict";
import {registerStaleRoomRoutes} from "../src/room_stale_reconciliation.js";

const timestamp = ms => ({toMillis: () => ms});

test("stale reconciliation eventually scans past the first 45 open rooms", async () => {
  const start = Date.parse("2026-11-01T12:00:00Z");
  let now = start;
  let route;
  const records = Array.from({length: 51}, (_, i) => ({
    id: String(i).padStart(3, "0"),
    data: {
      isOpen: true,
      createdAt: timestamp(start - 10 * 60 * 1000),
    },
  }));
  for (const room of records) {
    room.ref = {
      kind: "room",
      id: room.id,
      collection: (name) => {
        assert.equal(name, "participants");
        return {limit: () => ({kind: "participants", id: room.id})};
      },
    };
  }
  function query(after) {
    return {
      startAfter: (doc) => query(doc.id),
      limit: (max) => ({
        get: async () => {
          const docs = records
            .filter(item => item.data.isOpen && (after == null || item.id > after))
            .slice(0, max)
            .map(item => ({
              id: item.id, ref: item.ref, data: () => item.data,
            }));
          return {docs, size: docs.length, empty: docs.length === 0};
        },
      }),
    };
  }
  const db = {
    collection: (name) => {
      assert.equal(name, "rooms");
      return {
        where: (field, op, value) => {
          assert.deepEqual([field, op, value], ["isOpen", "==", true]);
          return {orderBy: (fieldName) => {
            assert.equal(fieldName, "__name__");
            return query(null);
          }};
        },
      };
    },
    runTransaction: async (callback) => callback({
      get: async (ref) => {
        if (ref.kind === "participants") return {docs: []};
        const doc = records.find(item => item.id === ref.id);
        return {data: () => doc.data};
      },
      update: (ref, fields) => {
        const doc = records.find(item => item.id === ref.id);
        Object.assign(doc.data, fields);
      },
    }),
  };
  registerStaleRoomRoutes({
    app: {get: (path, handler) => {
      assert.equal(path, "/rooms/reconcile-stale");
      route = handler;
    }},
    db,
    authenticatedUser: async () => ({uid: "viewer"}),
    clock: () => now,
  });
  const call = async () => {
    let reply;
    await route({}, {json: value => {reply = value;}}, error => {throw error;});
    return reply;
  };
  const first = await call();
  assert.equal(first.closed, 45);
  assert.equal(records.filter(doc => doc.data.isOpen).length, 6);

  now += 60000;
  const second = await call();
  assert.equal(second.closed, 6);
  assert.equal(records.filter(doc => doc.data.isOpen).length, 0);
});
