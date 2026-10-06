import {FieldValue, Timestamp} from "firebase-admin/firestore";

const fail = (message, status = 400) => {
  throw Object.assign(new Error(message), {status});
};

function assertDirectChat(data, one, two) {
  const members = data?.memberIds;
  if (data?.active !== true ||
      data?.type === "group" ||
      !Array.isArray(members) ||
      members.length !== 2 ||
      !members.includes(one) ||
      !members.includes(two)) {
    fail("An approved direct conversation is required before calling.", 403);
  }
}

export function registerCallRoutes({app, db, authenticatedUser}) {
  app.post("/calls/start", async (req, res, next) => {
    try {
      const caller = await authenticatedUser(req);
      const recipientId = String(req.body?.recipientId || "").trim();
      const chatId = String(req.body?.chatId || "").trim();
      const type = String(req.body?.type || "").trim();
      if (!recipientId || recipientId === caller.uid ||
          !chatId || !["audio", "video"].includes(type)) {
        fail("Invalid call request.");
      }

      const chatRef = db.collection("chats").doc(chatId);
      const callerRef = db.collection("users").doc(caller.uid);
      const recipientRef = db.collection("users").doc(recipientId);
      const [chatSnap, callerSnap, recipientSnap] = await Promise.all([
        chatRef.get(),
        callerRef.get(),
        recipientRef.get(),
      ]);
      if (!chatSnap.exists || !callerSnap.exists || !recipientSnap.exists) {
        fail("Call participant is unavailable.", 404);
      }
      assertDirectChat(chatSnap.data(), caller.uid, recipientId);

      const existing = await db
        .collection("calls")
        .where("recipientId", "==", recipientId)
        .limit(30)
        .get();
      const busy = existing.docs.some(doc => {
        const data = doc.data() || {};
        return data.status === "ringing" || data.status === "accepted";
      });
      if (busy) fail("This member is already in another call.", 409);

      const callRef = db.collection("calls").doc();
      const channelId = "call_" + callRef.id;
      const callerData = callerSnap.data() || {};
      const recipientData = recipientSnap.data() || {};

      await callRef.set({
        callerId: caller.uid,
        callerName: String(
          callerData.displayName || caller.name || "WorldVoice",
        ),
        callerPhotoUrl: String(callerData.photoUrl || caller.picture || ""),
        recipientId,
        recipientName: String(
          recipientData.displayName || recipientData.name || "WorldVoice",
        ),
        recipientPhotoUrl: String(recipientData.photoUrl || ""),
        chatId,
        type,
        channelId,
        status: "ringing",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      res.json({
        ok: true,
        callId: callRef.id,
        channelId,
        type,
        status: "ringing",
      });
    } catch (error) {
      next(error);
    }
  });

  app.get("/calls/incoming", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const snapshot = await db
        .collection("calls")
        .where("recipientId", "==", user.uid)
        .limit(50)
        .get();

      const now = Date.now();
      const calls = snapshot.docs
        .map(doc => ({id: doc.id, ...(doc.data() || {})}))
        .filter(call => {
          if (call.status !== "ringing") return false;
          const created = call.createdAt?.toMillis?.() || 0;
          return created === 0 || now - created < 120000;
        })
        .sort((a, b) =>
          (b.createdAt?.toMillis?.() || 0) -
          (a.createdAt?.toMillis?.() || 0));

      const call = calls[0];
      if (!call) return res.json({ok: true, call: null});

      res.json({
        ok: true,
        call: {
          id: call.id,
          callerId: String(call.callerId || ""),
          callerName: String(call.callerName || "WorldVoice"),
          callerPhotoUrl: String(call.callerPhotoUrl || ""),
          recipientId: String(call.recipientId || ""),
          chatId: String(call.chatId || ""),
          type: String(call.type || "audio"),
          channelId: String(call.channelId || ""),
          status: String(call.status || "ringing"),
          createdAtMs: call.createdAt?.toMillis?.() || 0,
        },
      });
    } catch (error) {
      next(error);
    }
  });

  app.get("/calls/:callId/status", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const callId = String(req.params.callId || "").trim();
      const snap = await db.collection("calls").doc(callId).get();
      if (!snap.exists) fail("Call not found.", 404);
      const data = snap.data() || {};
      if (data.callerId !== user.uid && data.recipientId !== user.uid) {
        fail("Call access denied.", 403);
      }
      res.json({
        ok: true,
        status: String(data.status || "ended"),
        channelId: String(data.channelId || ""),
        type: String(data.type || "audio"),
      });
    } catch (error) {
      next(error);
    }
  });

  app.post("/calls/:callId/respond", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const callId = String(req.params.callId || "").trim();
      const action = String(req.body?.action || "").trim();
      if (!["accept", "decline"].includes(action)) {
        fail("Invalid call response.");
      }

      const callRef = db.collection("calls").doc(callId);
      const result = await db.runTransaction(async tx => {
        const snap = await tx.get(callRef);
        if (!snap.exists) fail("Call not found.", 404);
        const data = snap.data() || {};
        if (data.recipientId !== user.uid) {
          fail("Only the recipient can answer this call.", 403);
        }
        if (data.status !== "ringing") {
          return {
            status: String(data.status || "ended"),
            channelId: String(data.channelId || ""),
            type: String(data.type || "audio"),
          };
        }
        const status = action === "accept" ? "accepted" : "declined";
        tx.update(callRef, {
          status,
          acceptedAt: action === "accept"
            ? FieldValue.serverTimestamp()
            : null,
          endedAt: action === "decline"
            ? FieldValue.serverTimestamp()
            : null,
          updatedAt: FieldValue.serverTimestamp(),
        });
        return {
          status,
          channelId: String(data.channelId || ""),
          type: String(data.type || "audio"),
        };
      });

      res.json({ok: true, ...result});
    } catch (error) {
      next(error);
    }
  });

  app.post("/calls/:callId/end", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const callId = String(req.params.callId || "").trim();
      const callRef = db.collection("calls").doc(callId);

      const result = await db.runTransaction(async tx => {
        const snap = await tx.get(callRef);
        if (!snap.exists) return {status: "ended"};
        const data = snap.data() || {};
        if (data.callerId !== user.uid && data.recipientId !== user.uid) {
          fail("Call access denied.", 403);
        }
        if (data.status === "ended" || data.status === "declined") {
          return {status: String(data.status)};
        }

        const now = Timestamp.now();
        const acceptedAt = data.acceptedAt;
        const durationSeconds = acceptedAt?.toMillis
          ? Math.max(
              0,
              Math.floor((now.toMillis() - acceptedAt.toMillis()) / 1000),
            )
          : 0;

        tx.update(callRef, {
          status: "ended",
          endedBy: user.uid,
          endedAt: now,
          durationSeconds,
          updatedAt: now,
        });

        const chatId = String(data.chatId || "");
        if (chatId) {
          const chatRef = db.collection("chats").doc(chatId);
          const chatSnap = await tx.get(chatRef);
          if (chatSnap.exists) {
            assertDirectChat(
              chatSnap.data(),
              String(data.callerId || ""),
              String(data.recipientId || ""),
            );
            const messageRef = chatRef.collection("messages").doc();
            const label = data.type === "video"
              ? "Video call"
              : "Voice call";
            tx.create(messageRef, {
              type: "call",
              callType: String(data.type || "audio"),
              callId,
              senderId: String(data.callerId || ""),
              senderName: String(data.callerName || "WorldVoice"),
              durationSeconds,
              callStatus: data.status === "ringing"
                ? "missed"
                : "completed",
              text: label,
              createdAt: now,
            });
            tx.update(chatRef, {
              latestText: "📞 " + label,
              lastMessageAt: now,
            });
          }
        }
        return {status: "ended", durationSeconds};
      });

      res.json({ok: true, ...result});
    } catch (error) {
      next(error);
    }
  });
}
