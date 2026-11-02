import test from "node:test";
import assert from "node:assert/strict";
import {registerGiftWallRoutes} from "../src/gift_wall_routes.js";

function harness(viewerUid) {
  let handler;
  let chosenCollection;
  const docs = [{id: "receipt1", data: () => ({
    senderId: "alice", senderName: "Alice",
    recipientId: "bob", recipientName: "Bob",
    itemId: "wv_gift_001", giftId: "wv_gift_001",
    type: "gift", quantity: 1, priceCoins: 2,
  })}];
  const db = {collection: name => {
    assert.equal(name, "users");
    return {doc: uid => ({
      get: async () => ({exists: true}),
      collection: collection => {
        chosenCollection = collection;
        return {orderBy: () => ({limit: () => ({
          get: async () => ({docs}),
        })})};
      },
    })};
  }};
  registerGiftWallRoutes({
    app: {get: (_, callback) => {handler = callback;}},
    db, authenticatedUser: async () => ({uid: viewerUid}),
  });
  const request = (uid, direction) => new Promise((resolve, reject) => {
    let status = 200;
    const res = {
      status: code => {status = code; return res;},
      json: body => resolve({status, body}),
    };
    handler({params: {uid}, query: {direction}}, res, reject);
  });
  return {request, collection: () => chosenCollection};
}

test("received gifts are visible to other signed-in users", async () => {
  const wall = harness("another-viewer");
  const result = await wall.request("recipientABC", "received");
  assert.equal(result.status, 200);
  assert.equal(wall.collection(), "gift_notifications");
  assert.equal(result.body.items.length, 1);
});

test("sent history is private and never queried for a visitor", async () => {
  const wall = harness("another-viewer");
  const result = await wall.request("recipientABC", "sent");
  assert.equal(result.status, 403);
  assert.equal(wall.collection(), undefined);
});

test("owner can read their own sent history", async () => {
  const wall = harness("recipientABC");
  const result = await wall.request("recipientABC", "sent");
  assert.equal(result.status, 200);
  assert.equal(wall.collection(), "gift_wall_sent");
});
