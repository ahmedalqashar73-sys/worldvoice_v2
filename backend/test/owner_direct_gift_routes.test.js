import test from "node:test";
import assert from "node:assert/strict";
import {createHash} from "node:crypto";
import {readFileSync} from "node:fs";
import vm from "node:vm";
import {splitOwnerCoinSpend, diamondsForPaidCoins} from "../src/owner_coin_policy.js";

// Run the production handler with a deterministic transaction fake. This
// exercises the actual route, without writing to the live Firebase project.
const source = readFileSync(new URL("../src/owner_direct_gift_routes.js", import.meta.url), "utf8");
const route = source.slice(source.indexOf("export function registerOwnerDirectGiftRoutes"))
  .replace("export function registerOwnerDirectGiftRoutes",
    "function registerOwnerDirectGiftRoutes");

function harness({adminCoins = 60, coins = 180, blocked = false,
  owner = true} = {}) {
  const docs = new Map([
    ["users/owner", {displayName: "Owner"}],
    ["users/friend", {displayName: "Friend"}],
    ["users/owner/private/wallet", {
      coins, adminCoins, diamondsPending: 0, giftSentPoints: 0,
    }],
    ["users/friend/private/wallet", {diamondsPending: 0}],
    ["economy_config/current", {
      enabled: true, coinsPerUsd: 100, receiverSharePercent: 50,
      diamondUsdValue: .01, holdDays: 7, giftLevelPointsPerCoin: 1,
    }],
    ["store_items/gift__wv_gift_023", {
      type: "gift", active: true, priceCoins: 100, requiredGiftLevel: 0,
    }],
  ]);
  if (blocked) docs.set("users/friend/blocked_peers/owner", {});
  const ref = path => ({
    path, collection: name => ref(path + "/" + name),
    doc: id => ref(path + "/" + id),
  });
  const writes = [];
  const tx = {
    get: async target => ({
      exists: docs.has(target.path), data: () => docs.get(target.path),
    }),
    update: (target, data) => {
      writes.push({kind: "update", path: target.path, data});
      docs.set(target.path, {...docs.get(target.path), ...data});
    },
    create: (target, data) => {
      assert.equal(docs.has(target.path), false,
        "duplicate ledger or gift delivery receipt");
      writes.push({kind: "create", path: target.path, data});
      docs.set(target.path, data);
    },
    set: (target, data) => {
      writes.push({kind: "set", path: target.path, data});
      docs.set(target.path, {...docs.get(target.path), ...data});
    },
  };
  let handler;
  const app = {post: (path, fn) => {
    assert.equal(path, "/gift/owner-direct");
    handler = fn;
  }};
  const context = {
    app, db: {
      collection: name => ref(name), doc: ref,
      runTransaction: async fn => fn(tx),
    },
    authenticatedUser: async () => ({uid: "owner", email_verified: true}),
    isVerifiedOwner: () => owner,
    notifyGift: async () => {},
    createHash,
    worldVoiceGiftCatalog: new Map([["wv_gift_023", {
      name: "Crimson Dragon", nameAr: "التنين القرمزي", priceCoins: 100,
    }]]),
    approvedWorldVoiceGift: (id, price) =>
      id === "wv_gift_023" && price === 100,
    requireLiveEconomy: value => value,
    requirePrivateWallet: snap => {
      if (!snap.exists) throw new Error("Private wallet required.");
    },
    giftProgress: data => ({
      points: Number(data.giftSentPoints || 0), level: 1,
    }),
    privateWalletRef: user => ref(user.path + "/private/wallet"),
    splitOwnerCoinSpend, diamondsForPaidCoins,
    // The handler checks the canonical two-member chat only when it exists.
    chatIdFor: () => 'a'.repeat(64),
    assertChatMembership: () => true,
    FieldValue: {
      serverTimestamp: () => "timestamp",
      increment: amount => ({increment: amount}),
    },
    Timestamp: {fromMillis: value => ({toMillis: () => value})},
  };
  vm.runInNewContext(route +
    "\nregisterOwnerDirectGiftRoutes({app, db, authenticatedUser, isVerifiedOwner, notifyGift});",
  context);
  async function send({requestKey = "test-request-key-123456", recipientId = "friend"} = {}) {
    let status = 200;
    let payload;
    let error;
    const res = {
      status: n => {status = n; return res;},
      json: value => {payload = value; return res;},
    };
    await handler({
      body: {giftId: "wv_gift_023", recipientId, quantity: 1},
      headers: {"idempotency-key": requestKey},
    }, res, err => {error = err;});
    return {status, payload, error};
  }
  return {docs, writes, send};
}

test("direct gifts atomically spend free coins first and settle only paid coins", async () => {
  const h = harness();
  const r = await h.send();
  assert.equal(r.error, undefined);
  assert.equal(r.payload.chargedCoins, 100);
  assert.equal(r.payload.adminCoinsSpent, 60);
  assert.equal(r.payload.paidCoinsSpent, 40);
  assert.equal(r.payload.pendingDiamonds, 20);
  const wallet = h.docs.get("users/owner/private/wallet");
  assert.equal(wallet.coins, 80);
  assert.equal(wallet.adminCoins, 0);
  assert.equal(h.docs.get("users/friend/private/wallet").diamondsPending, 20);
  assert.equal(h.docs.get("users/friend/gift_notifications/" +
    createHash("sha256").update("owner-direct:owner:test-request-key-123456")
      .digest("hex")).type, "gift");
  const count = h.writes.length;
  const retry = await h.send();
  assert.equal(retry.payload.alreadyProcessed, true);
  assert.equal(h.writes.length, count);
});

test("fully admin-funded owner gift never creates withdrawable diamonds", async () => {
  const h = harness({adminCoins: 180});
  const r = await h.send();
  assert.equal(r.payload.pendingDiamonds, 0);
  assert.equal(h.docs.get("users/friend/private/wallet").diamondsPending, 0);
  assert.equal([...h.docs.keys()].some(k => k.includes("/diamond_lots/")), false);
});

test("direct gifting rejects blocked recipients and nonowners without debit", async () => {
  for (const options of [{blocked: true}, {owner: false}]) {
    const h = harness(options);
    const r = await h.send();
    assert.ok(r.error?.status === 403 || r.status === 403);
    assert.equal(h.writes.length, 0);
    assert.equal(h.docs.get("users/owner/private/wallet").coins, 180);
  }
});
