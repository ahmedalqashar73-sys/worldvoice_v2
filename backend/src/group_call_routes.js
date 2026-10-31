import {FieldValue} from "firebase-admin/firestore";

const fail = (message, status = 400) => {
  throw Object.assign(new Error(message), {status});
};

export function assertGroupCallMembership(chat, uid) {
  if (chat?.active !== true || chat.type !== "group" ||
      !Array.isArray(chat.memberIds) ||
      chat.memberIds.length < 3 || chat.memberIds.length > 30 ||
      !chat.memberIds.includes(uid)) {
    fail("Active group membership required.", 403);
  }
}

function validId(id) {
  return /^[A-Za-z0-9_-]{8,160}$/.test(id);
}

function publicCall(id, data) {
  return {
    id,
    chatId: String(data.chatId || id),
    groupName: String(data.groupName || "WorldVoice group"),
    channelId: String(data.channelId || ""),
    type: data.type === "video" ? "video" : "audio",
    status: String(data.status || "ended"),
    ownerId: String(data.ownerId || ""),
    memberIds: Array.isArray(data.memberIds) ? data.memberIds : [],
    joinedIds: Array.isArray(data.joinedIds) ? data.joinedIds : [],
    declinedIds: Array.isArray(data.declinedIds) ? data.declinedIds : [],
    memberNames: data.memberNames || {},
    createdAtMs: data.createdAt?.toMillis?.() || 0,
  };
}

export function registerGroupCallRoutes({app, db, authenticatedUser}) {
  const calls = db.collection("group_calls");

  async function memberCall(uid, chatId) {
    if (!validId(chatId)) fail("Invalid group ID.");
    const chatSnap = await db.collection("chats").doc(chatId).get();
    if (!chatSnap.exists) fail("Group unavailable.", 404);
    assertGroupCallMembership(chatSnap.data(), uid);
    const callSnap = await calls.doc(chatId).get();
    return {chat: chatSnap.data(), call: callSnap};
  }

  app.post("/calls/group/start", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const chatId = String(req.body?.chatId || "").trim();
      const type = String(req.body?.type || "").trim();
      if (!validId(chatId) || !["audio", "video"].includes(type)) {
        fail("Invalid group call request.");
      }
      const chatRef = db.collection("chats").doc(chatId);
      const callRef = calls.doc(chatId);
      const result = await db.runTransaction(async tx => {
        const [chatSnap, activeSnap] = await Promise.all([
          tx.get(chatRef), tx.get(callRef),
        ]);
        if (!chatSnap.exists) fail("Group unavailable.", 404);
        const chat = chatSnap.data() || {};
        assertGroupCallMembership(chat, user.uid);
        if (activeSnap.exists && activeSnap.data()?.status === "active") {
          const active = activeSnap.data();
          if (active.type !== type) {
            fail("Another group call is already active.", 409);
          }
          tx.update(callRef, {
            joinedIds: FieldValue.arrayUnion(user.uid),
            declinedIds: FieldValue.arrayRemove(user.uid),
            updatedAt: FieldValue.serverTimestamp(),
          });
          return publicCall(chatId, {
            ...active,
            joinedIds: [...new Set([...(active.joinedIds || []), user.uid])],
          });
        }

        const call = {
          chatId,
          groupName: String(chat.groupName || "WorldVoice group"),
          memberIds: chat.memberIds,
          memberNames: chat.memberNames || {},
          channelId: "group_" + chatId,
          type,
          status: "active",
          ownerId: user.uid,
          joinedIds: [user.uid],
          declinedIds: [],
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        };
        tx.set(callRef, call);
        return publicCall(chatId, call);
      });
      res.json({ok: true, call: result});
    } catch (error) { next(error); }
  });

  app.get("/calls/group/incoming", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const snap = await calls.where("memberIds", "array-contains", user.uid)
        .limit(30).get();
      const cutoff = Date.now() - 90 * 1000;
      const eligible = snap.docs
        .filter(doc => {
          const call = doc.data();
          const at = call.createdAt?.toMillis?.() || 0;
          return call.status === "active" &&
            call.ownerId !== user.uid &&
            !(call.joinedIds || []).includes(user.uid) &&
            !(call.declinedIds || []).includes(user.uid) &&
            at > cutoff;
        })
        .sort((a, b) => (b.data().createdAt?.toMillis?.() || 0) -
          (a.data().createdAt?.toMillis?.() || 0));
      if (!eligible.length) return res.json({ok: true, call: null});
      const candidate = eligible[0];
      // A removed group member cannot be invited from a stale call snapshot.
      const chatSnap = await db.collection("chats").doc(candidate.id).get();
      if (!chatSnap.exists) return res.json({ok: true, call: null});
      try {
        assertGroupCallMembership(chatSnap.data(), user.uid);
      } catch (_) {
        return res.json({ok: true, call: null});
      }
      res.json({ok: true, call: publicCall(candidate.id, candidate.data())});
    } catch (error) { next(error); }
  });

  app.get("/calls/group/:chatId/status", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const chatId = String(req.params.chatId || "");
      const {call} = await memberCall(user.uid, chatId);
      res.json({
        ok: true,
        call: call.exists ? publicCall(call.id, call.data()) : null,
      });
    } catch (error) { next(error); }
  });

  app.post("/calls/group/:chatId/join", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const chatId = String(req.params.chatId || "");
      if (!validId(chatId)) fail("Invalid group ID.");
      const chatRef = db.collection("chats").doc(chatId);
      const callRef = calls.doc(chatId);
      const result = await db.runTransaction(async tx => {
        const [chatSnap, callSnap] = await Promise.all([
          tx.get(chatRef), tx.get(callRef),
        ]);
        if (!chatSnap.exists) fail("Group unavailable.", 404);
        assertGroupCallMembership(chatSnap.data(), user.uid);
        if (!callSnap.exists || callSnap.data().status !== "active") {
          fail("Group call has ended.", 410);
        }
        tx.update(callRef, {
          joinedIds: FieldValue.arrayUnion(user.uid),
          declinedIds: FieldValue.arrayRemove(user.uid),
          updatedAt: FieldValue.serverTimestamp(),
        });
        const call = callSnap.data();
        return publicCall(chatId, {
          ...call,
          joinedIds: [...new Set([...(call.joinedIds || []), user.uid])],
        });
      });
      res.json({ok: true, call: result});
    } catch (error) { next(error); }
  });

  app.post("/calls/group/:chatId/decline", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const chatId = String(req.params.chatId || "");
      const {call} = await memberCall(user.uid, chatId);
      if (call.exists && call.data()?.status === "active") {
        await call.ref.update({
          declinedIds: FieldValue.arrayUnion(user.uid),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
      res.json({ok: true});
    } catch (error) { next(error); }
  });

  app.post("/calls/group/:chatId/leave", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const chatId = String(req.params.chatId || "");
      if (!validId(chatId)) fail("Invalid group ID.");
      const callRef = calls.doc(chatId);
      await db.runTransaction(async tx => {
        const snap = await tx.get(callRef);
        if (!snap.exists || snap.data()?.status !== "active") return;
        const data = snap.data();
        if (!data.memberIds?.includes(user.uid)) {
          fail("Group call access denied.", 403);
        }
        const remaining = (data.joinedIds || [])
          .filter(id => id !== user.uid);
        tx.update(callRef, {
          joinedIds: FieldValue.arrayRemove(user.uid),
          ...(remaining.length === 0
            ? {status: "ended", endedAt: FieldValue.serverTimestamp()} : {}),
          updatedAt: FieldValue.serverTimestamp(),
        });
      });
      res.json({ok: true});
    } catch (error) { next(error); }
  });

  app.post("/calls/group/:chatId/end", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const chatId = String(req.params.chatId || "");
      if (!validId(chatId)) fail("Invalid group ID.");
      const callRef = calls.doc(chatId);
      await db.runTransaction(async tx => {
        const snap = await tx.get(callRef);
        if (!snap.exists || snap.data()?.status !== "active") return;
        if (snap.data()?.ownerId !== user.uid) {
          fail("Only the group call host can end it for everyone.", 403);
        }
        tx.update(callRef, {
          status: "ended",
          joinedIds: [],
          endedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      });
      res.json({ok: true});
    } catch (error) { next(error); }
  });
}
