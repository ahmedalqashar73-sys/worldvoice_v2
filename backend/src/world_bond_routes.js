// WorldBond: server-authoritative social relationships and non-monetary
// partner learning. Never modify existing room/live or private wallet fields.
import {createHash} from "node:crypto";
import {FieldValue} from "firebase-admin/firestore";
import {chatIdFor} from "./chat_membership.js";
import {worldBondSpecialGiftCatalog} from "./gift_catalog.js";

export const BOND_TYPES = Object.freeze(["learning", "language", "friend", "duo"]);
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

// Public quiz choices but private scoring: responses never include the correct
// option before the only permitted attempt for this UTC day.
export const worldBondExercises = Object.freeze([
  {language: "en", question: "Choose the past-tense sentence.",
    choices: ["I go yesterday.", "I went yesterday.", "I going yesterday."],
    answer: 1, explanation: "Went is the past tense of go."},
  {language: "en", question: "Which request is more polite?",
    choices: ["Give me water.", "Can I have some water, please?", "Water now."],
    answer: 1, explanation: "Could or can plus please is a polite request."},
  {language: "es", question: "Choose the Spanish greeting meaning good morning.",
    choices: ["Buenas noches", "Buenos días", "Hasta luego"],
    answer: 1, explanation: "Buenos días means good morning."},
  {language: "fr", question: "How do you say thank you in French?",
    choices: ["Merci", "Bonsoir", "Au revoir"],
    answer: 0, explanation: "Merci means thank you."},
  {language: "zh", question: "Which Chinese phrase means hello?",
    choices: ["谢谢", "你好", "再见"],
    answer: 1, explanation: "你好 (nǐ hǎo) is hello."},
  {language: "ko", question: "Which Korean phrase is a polite hello?",
    choices: ["안녕하세요", "감사합니다", "잘 가요"],
    answer: 0, explanation: "안녕하세요 (annyeonghaseyo) is hello."},
]);
export const exerciseForDay = (id, day) => {
  const digest = createHash("sha256").update(id + ":" + day).digest();
  return worldBondExercises[digest[0] % worldBondExercises.length];
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
      const viewedId = validId(peerId) ? peerId : user.uid;
      const [records, wishSnap, wallSnap, catalogSnap, bondGiftsSnap] = await Promise.all([
        bonds.where("members", "array-contains", user.uid).limit(80).get(),
        profiles.doc(viewedId).collection("worldbond").doc("wishlist").get(),
        db.collection("economy_audit")
          .where("recipientId", "==", viewedId).limit(70).get(),
        db.collection("store_items").limit(150).get(),
        validId(peerId) && peerId !== user.uid
          ? Promise.all(BOND_TYPES.map(type => bonds.doc(bondKey(user.uid, peerId, type))
            .collection("gifts").orderBy("createdAt", "desc").limit(20).get()))
            .then(pages => ({docs: pages.flatMap(page => page.docs)}))
          : Promise.resolve({docs: []}),
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
        && d.data()?.recipientId === viewedId)
        .slice(0, 25).map(d => ({
          itemId: clean(d.data()?.itemId || d.data()?.giftId || "gift", 100),
          senderId: clean(d.data()?.senderId, 128),
          type: clean(d.data()?.type, 30),
        }));
      res.json({ok: true, bonds: filtered, catalog, wishes, wall,
        specialGifts: worldBondSpecialGiftCatalog,
        bondGifts: bondGiftsSnap.docs.filter(s => {
          const d = s.data();
          return [user.uid, peerId].includes(d.senderId) &&
            [user.uid, peerId].includes(d.recipientId);
        }).map(s => ({id: s.id, giftId: s.data().giftId,
          senderId: s.data().senderId, recipientId: s.data().recipientId})),
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

  // Reuse the existing paid /gift/send chat transaction, including wallet
  // holds, idempotency, self-gift rejection and catalog price verification.
  // Never create an alternate gift settlement path here.
  app.get("/world-bond/chat-context", async (req, res, next) => {
    try {
      const viewer = await authenticatedUser(req);
      const peerId = clean(req.query.peerId, 128);
      if (!validId(peerId) || peerId === viewer.uid) {
        bad("Choose a different recipient.");
      }
      // Share the exact member-validated identity used by private chat.
      const chatId = chatIdFor(viewer.uid, peerId);
      const [chat, follow, followedBack, blocked, blocksBack] =
        await Promise.all([
          db.collection("chats").doc(chatId).get(),
          profiles.doc(viewer.uid).collection("following").doc(peerId).get(),
          profiles.doc(peerId).collection("following").doc(viewer.uid).get(),
          profiles.doc(viewer.uid).collection("blocked_peers").doc(peerId).get(),
          profiles.doc(peerId).collection("blocked_peers").doc(viewer.uid).get(),
        ]);
      if (blocked.exists || blocksBack.exists) bad("Member blocked.", 403);
      if (!follow.exists || !followedBack.exists || !chat.exists ||
          chat.data()?.active !== true ||
          !Array.isArray(chat.data()?.memberIds) ||
          chat.data().memberIds.length !== 2 ||
          !chat.data().memberIds.includes(viewer.uid) ||
          !chat.data().memberIds.includes(peerId)) {
        bad("Mutual following and active private chat required for a paid gift.", 403);
      }
      res.json({ok: true, chatId});
    } catch (e) {next(e);}
  });

  app.get("/world-bond/challenge", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const peerId = clean(req.query.peerId, 128);
      const type = clean(req.query.type, 20);
      const ref = requirePair(user.uid, peerId, type);
      const snap = await ref.get();
      const data = pairStatus(snap, user.uid);
      if (data.status !== "active") bad("Accept the connection first.", 409);
      const day = clockDay(clock());
      const receipt = await ref.collection("quiz_days").doc(day).get();
      const exercise = exerciseForDay(ref.id, day);
      const attempted = receipt.data()?.attempted || [];
      res.json({ok: true, day, language: exercise.language,
        question: exercise.question, choices: exercise.choices,
        alreadyAttempted: attempted.includes(user.uid),
        pairCompleted: receipt.data()?.completed === true});
    } catch (e) {next(e);}
  });

  app.post("/world-bond/challenge/answer", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const peerId = clean(req.body?.peerId, 128);
      const type = clean(req.body?.type, 20);
      const answerIndex = req.body?.answerIndex;
      if (!Number.isInteger(answerIndex) ||
          answerIndex < 0 || answerIndex >= 3) bad("Choose a valid answer.");
      const ref = requirePair(user.uid, peerId, type);
      const day = clockDay(clock()), receiptRef =
        ref.collection("quiz_days").doc(day);
      const exercise = exerciseForDay(ref.id, day);
      const correct = answerIndex === exercise.answer;
      const result = await db.runTransaction(async tx => {
        const [bond, prior] = await Promise.all([
          tx.get(ref), tx.get(receiptRef),
        ]);
        const data = pairStatus(bond, user.uid);
        if (data.status !== "active") bad("Connection not active.", 409);
        const attempted = prior.data()?.attempted || [];
        if (attempted.includes(user.uid)) bad("Already answered today.", 409);
        const correctMembers = prior.data()?.correctMembers || [];
        const nextCorrect = correct ? [...correctMembers, user.uid] : correctMembers;
        const completed = nextCorrect.length === 2;
        const xp = Number(data.xp || 0);
        if (!Number.isSafeInteger(xp) || xp < 0) bad("XP state invalid.", 409);
        tx.set(receiptRef, {attempted: [...attempted, user.uid],
          correctMembers: nextCorrect, completed, day,
          updatedAtMs: clock()}, {merge: true});
        if (completed) tx.update(ref, {xp: xp + 50, updatedAtMs: clock()});
        return {correct, pairCompleted: completed, xp: xp + (completed ? 50 : 0)};
      });
      res.json({ok: true, ...result, explanation: exercise.explanation,
        level: bondLevel(result.xp)});
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
      const snaps = items.length === 0 ? [] : await db.getAll(...items.map(id =>
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
