// WorldBond: server-authoritative social relationships and non-monetary
// partner learning. Never modify existing room/live or private wallet fields.
import {createHash} from "node:crypto";
import {FieldValue} from "firebase-admin/firestore";

export const BOND_TYPES = Object.freeze(["language", "friend", "duo"]);
export const bondKey = (a, b, type) => createHash("sha256")
  .update([a, b].sort().join(":") + ":" + type).digest("hex");
export const bondLevel = xp => xp >= 2200 ? 5 :
  xp >= 1200 ? 4 : xp >= 600 ? 3 : xp >= 200 ? 2 : 1;
const bad = (msg, status = 400) => {
  throw Object.assign(new Error(msg), {status});
};
const validId = v => typeof v === "string" &&
  /^[A-Za-z0-9_-]{1,128}$/.test(v);
const clean = (value, max = 250) =>
  typeof value === "string" ? value.trim().slice(0, max) : "";
const clockDay = now => new Date(now).toISOString().slice(0, 10);
const asBond = snap => {
  const d = snap.data() || {};
  return {id: snap.id, members: d.members ?? [], inviterId: d.inviterId,
    recipientId: d.recipientId, type: d.type, status: d.status,
    expiresAtMs: d.expiresAtMs, xp: Number(d.xp || 0),
    level: bondLevel(Number(d.xp || 0)), completedDays: d.completedDays || 0,
    updatedAtMs: d.updatedAtMs || 0};
};

export function registerWorldBondRoutes({app, db, authenticatedUser,
  clock = Date.now}) {
  const bonds = db.collection("world_bonds");
  const profiles = db.collection("users");
  const requirePair = (uid, peer, type) => {
    if (!validId(peer) || peer === uid || !BOND_TYPES.includes(type)) {
      bad("Choose another existing member and valid relationship type.");
    }
    return bonds.doc(bondKey(uid, peer, type));
  };
  const checkBlock = async (tx, a, b) => {
    const [one, two] = await Promise.all([
      tx.get(profiles.doc(a).collection("blocked_peers").doc(b)),
      tx.get(profiles.doc(b).collection("blocked_peers").doc(a)),
    ]);
    if (one.exists || two.exists) bad("Relationship blocked.", 403);
  };
  const pairStatus = (snap, uid) => {
    const d = snap.data() || {};
    if (!snap.exists || !d.members?.includes(uid)) bad("Not a member.", 403);
    return d;
  };

  app.get("/world-bond/overview", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const peerId = clean(req.query.peerId, 128);
      const [records, wishSnap, wallSnap, catalogSnap] = await Promise.all([
        bonds.where("members", "array-contains", user.uid).limit(80).get(),
        validId(peerId) ? profiles.doc(peerId)
          .collection("worldbond").doc("wishlist").get() : Promise.resolve(null),
        validId(peerId) ? db.collection("economy_audit")
          .where("recipientId", "==", peerId).limit(70).get()
          : Promise.resolve(null),
        db.collection("store_items").limit(150).get(),
      ]);
      // Allow only participants to see pair activity. Gift audit shows only
      // public-facing item identifiers, never wallet details or private amounts.
      const filtered = records.docs.map(asBond).filter(d =>
        (d.members.includes(user.uid)) &&
        (d.status === "active" || d.status === "pending") &&
        (d.status !== "pending" || d.expiresAtMs > clock()));
      const catalog = catalogSnap.docs.filter(d =>
        d.data()?.active === true &&
        ["gift", "vip"].includes(d.data()?.type) &&
        Number.isSafeInteger(d.data()?.priceCoins) &&
        d.data().priceCoins > 0).slice(0, 45).map(d => ({
          id: d.id, name: clean(d.data()?.name || d.id, 90),
          type: d.data().type, priceCoins: d.data().priceCoins,
        }));
      const wishIds = Array.isArray(wishSnap?.data()?.items) ?
        wishSnap.data().items.slice(0, 3) : [];
      const wishes = wishIds.map(id => catalog.find(c => c.id === id))
        .filter(Boolean);
      const wall = (wallSnap?.docs || []).filter(d =>
        ["item_gift", "gift_send", "gift"].includes(d.data()?.type)
        && d.data()?.recipientId === peerId)
        .slice(0, 25).map(d => ({
          itemId: clean(d.data()?.itemId || d.data()?.giftId || "gift", 100),
          senderId: clean(d.data()?.senderId, 128),
          type: clean(d.data()?.type, 30),
        }));
      res.json({ok: true, bonds: filtered, catalog, wishes, wall,
        partnerId: peerId || null, serverNowMs: clock()});
    } catch (e) {next(e);}
  });

  app.post("/world-bond/invite", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const peerId = clean(req.body?.peerId, 128);
      const type = clean(req.body?.type, 20);
      const ref = requirePair(user.uid, peerId, type);
      const now = clock(), day = clockDay(now);
      const rate = profiles.doc(user.uid).collection("worldbond").doc("invite_" + day);
      const result = await db.runTransaction(async tx => {
        const [prior, from, to, usage] = await Promise.all([
          tx.get(ref), tx.get(profiles.doc(user.uid)),
          tx.get(profiles.doc(peerId)), tx.get(rate),
        ]);
        if (!from.exists || !to.exists) bad("Profile not found.", 404);
        await checkBlock(tx, user.uid, peerId);
        const d = prior.data() || {};
        if (d.status === "active") return {status: "active", id: ref.id};
        if (d.status === "pending" && d.expiresAtMs > now) {
          if (d.inviterId !== user.uid) bad("Respond to the incoming invitation.", 409);
          return {status: "pending", id: ref.id, alreadySent: true};
        }
        const count = Number(usage.data()?.count || 0);
        if (!Number.isSafeInteger(count) || count >= 8) {
          bad("Daily invitation limit reached.", 429);
        }
        tx.set(rate, {count: count + 1, day, updatedAtMs: now}, {merge: true});
        tx.set(ref, {members: [user.uid, peerId].sort(), inviterId: user.uid,
          recipientId: peerId, type, status: "pending", expiresAtMs: now + 48 * 3600000,
          xp: 0, completedDays: 0, updatedAtMs: now});
        return {status: "pending", id: ref.id};
      });
      res.json({ok: true, ...result});
    } catch (e) {next(e);}
  });

  app.post("/world-bond/respond", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const peerId = clean(req.body?.peerId, 128);
      const type = clean(req.body?.type, 20);
      const decision = clean(req.body?.decision, 16);
      if (!["accept", "decline", "cancel", "leave"].includes(decision)) {
        bad("Invalid response.");
      }
      const ref = requirePair(user.uid, peerId, type);
      const now = clock();
      const result = await db.runTransaction(async tx => {
        const snap = await tx.get(ref);
        const data = pairStatus(snap, user.uid);
        const pending = data.status === "pending" && data.expiresAtMs > now;
        if (decision === "leave") {
          if (data.status !== "active") bad("Relationship is not active.", 409);
          tx.update(ref, {status: "ended", updatedAtMs: now});
          return {status: "ended"};
        }
        if (!pending) bad("Invitation expired or already resolved.", 409);
        if (decision === "cancel" && data.inviterId !== user.uid) {
          bad("Only the sender can cancel.", 403);
        }
        if (["accept", "decline"].includes(decision) &&
          data.recipientId !== user.uid) bad("Only recipient can respond.", 403);
        if (decision === "accept") await checkBlock(tx, user.uid, peerId);
        const status = decision === "accept" ? "active" :
          decision === "decline" ? "declined" : "cancelled";
        tx.update(ref, {status, updatedAtMs: now});
        return {status};
      });
      res.json({ok: true, ...result});
    } catch (e) {next(e);}
  });

  app.post("/world-bond/practice", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const peerId = clean(req.body?.peerId, 128);
      const type = clean(req.body?.type, 20);
      const ref = requirePair(user.uid, peerId, type);
      const now = clock(), today = clockDay(now);
      const receipt = ref.collection("practice_days").doc(today);
      const outcome = await db.runTransaction(async tx => {
        const [snap, prior] = await Promise.all([tx.get(ref), tx.get(receipt)]);
        const data = pairStatus(snap, user.uid);
        if (data.status !== "active" || !Number.isSafeInteger(data.xp || 0)) {
          bad("Accept a WorldBond invitation first.", 409);
        }
        const participants = Array.isArray(prior.data()?.participants) ?
          prior.data().participants : [];
        if (participants.includes(user.uid)) {
          return {xp: data.xp || 0, completed: participants.length === 2,
            alreadyChecked: true};
        }
        const nextMembers = [...participants, user.uid];
        if (nextMembers.length > 2) bad("Invalid practice membership.", 409);
        const completed = nextMembers.length === 2;
        // Check-in only; it does not assert verified learning or mint coins.
        // Each account may check in once per UTC day and a pair earns
        // 40 non-monetary friendship XP only after BOTH participants confirm.
        tx.set(receipt, {participants: nextMembers, day: today,
          updatedAtMs: now}, {merge: true});
        if (completed) tx.update(ref, {xp: (data.xp || 0) + 40,
          completedDays: (data.completedDays || 0) + 1, updatedAtMs: now});
        return {xp: (data.xp || 0) + (completed ? 40 : 0), completed};
      });
      res.json({ok: true, ...outcome, level: bondLevel(outcome.xp)});
    } catch (e) {next(e);}
  });

  app.post("/world-bond/wishlist", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const items = req.body?.items;
      if (!Array.isArray(items) || items.length > 3 ||
        new Set(items).size !== items.length ||
        items.some(x => typeof x !== "string" ||
          !/^(gift|vip)__[A-Za-z0-9_-]{1,80}$/.test(x))) {
        bad("Choose up to three distinct published gifts or VIP items.");
      }
      const snaps = await db.getAll(...items.map(id =>
        db.collection("store_items").doc(id)));
      for (const snap of snaps) {
        if (!snap.exists || snap.data()?.active !== true ||
          !["gift", "vip"].includes(snap.data()?.type)) {
          bad("A selected wishlist item is not available.", 409);
        }
      }
      await profiles.doc(user.uid).collection("worldbond").doc("wishlist").set({
        items, updatedAt: FieldValue.serverTimestamp(),
      });
      res.json({ok: true, items});
    } catch (e) {next(e);}
  });
}
