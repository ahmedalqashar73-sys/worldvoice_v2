import test from "node:test";
import assert from "node:assert/strict";
import {validateBetaContextMembership, registerOwnerBetaContextGiftRoutes, ownerBetaGiftEligibility} from "../src/owner_beta_context_gifts.js";

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

test("live owner test gifts allow genuine audience viewer only", () => {
  const now = Date.now();
  const base = {
    context: "live", now, senderId: "host", recipientId: "viewer",
    session: {isLive: true, hostId: "host",
      hostHeartbeatAt: {toMillis: () => now - 1000}},
    senderMember: {exists: false},
    recipientMember: {exists: false},
    recipientViewer: yes({uid: "viewer"}),
  };
  assert.equal(validateBetaContextMembership(base), true);
  assert.equal(validateBetaContextMembership({...base,
    recipientViewer: yes({uid: "other"})}), false);
  assert.equal(validateBetaContextMembership({...base,
    recipientViewer: {exists: false}}), false);
  assert.equal(validateBetaContextMembership({...base,
    senderId: "attacker", senderMember: yes({uid: "other"})}), false);
});

test("admin gifting reports why the owner cannot send without bypassing wallet security", () => {
  const wallet = {coins: 9825, adminCoins: 9825};
  assert.deepEqual(ownerBetaGiftEligibility({enabled: true, verified: true, wallet}),
    {available: true, reason: "READY"});
  assert.equal(ownerBetaGiftEligibility({enabled: true, verified: false, wallet}).reason,
    "OWNER_NOT_VERIFIED");
  assert.equal(ownerBetaGiftEligibility({enabled: false, verified: true, wallet}).reason,
    "BETA_DISABLED");
  assert.equal(ownerBetaGiftEligibility({enabled: true, verified: true,
    wallet: {coins: 9825, adminCoins: 0}}).reason, "NO_ADMIN_COINS");
  assert.equal(ownerBetaGiftEligibility({enabled: true, verified: true,
    wallet: null}).reason, "PRIVATE_WALLET_MISSING");
  assert.equal(ownerBetaGiftEligibility({enabled: true, verified: true,
    wallet: {...wallet, walletFrozen: true}}).reason, "WALLET_RESTRICTED");
});

test("owner beta status is server-gated and does not trust client build flags", async () => {
  let check;
  // The readiness endpoint must read only the authenticated owner's wallet.
  const wallet = {exists: true, data: () => ({coins: 9825, adminCoins: 9825})};
  const ownerDoc = {
    parent: {id: "users"},
    collection: () => ({doc: () => ({get: async () => wallet})}),
  };
  const db = {collection: () => ({doc: () => ownerDoc})};
  registerOwnerBetaContextGiftRoutes({
    app: {get: (_path, cb) => {check = cb;}, post: () => {}},
    db, validChannelName: () => true,
    authenticatedUser: async () => ({uid: "test-owner"}),
    isVerifiedOwner: async () => true,
  });
  const original = process.env.WORLDVOICE_OWNER_BETA_GIFTS_ENABLED;
  const res = {set: () => {}, json: x => x};
  try {
    process.env.WORLDVOICE_OWNER_BETA_GIFTS_ENABLED = "false";
    assert.equal((await check({}, res, e => {throw e;})).available, false);
    process.env.WORLDVOICE_OWNER_BETA_GIFTS_ENABLED = "true";
    assert.equal((await check({}, res, e => {throw e;})).available, true);
  } finally {
    if (original === undefined) delete process.env.WORLDVOICE_OWNER_BETA_GIFTS_ENABLED;
    else process.env.WORLDVOICE_OWNER_BETA_GIFTS_ENABLED = original;
  }
});

test("unverified account cannot activate owner gifts", async () => {
  let check;
  registerOwnerBetaContextGiftRoutes({
    app: {get: (_path, cb) => {check = cb;}, post: () => {}},
    db: null, validChannelName: () => true,
    authenticatedUser: async () => ({uid: "not-owner"}),
    isVerifiedOwner: async () => false,
  });
  const original = process.env.WORLDVOICE_OWNER_BETA_GIFTS_ENABLED;
  try {
    process.env.WORLDVOICE_OWNER_BETA_GIFTS_ENABLED = "true";
    assert.equal((await check({}, {set: () => {}, json: x => x},
      e => {throw e;})).available, false);
  } finally {
    if (original === undefined) delete process.env.WORLDVOICE_OWNER_BETA_GIFTS_ENABLED;
    else process.env.WORLDVOICE_OWNER_BETA_GIFTS_ENABLED = original;
  }
});
