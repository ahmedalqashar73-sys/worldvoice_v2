import {createHash} from "node:crypto";
import {FieldValue} from "firebase-admin/firestore";
import {chatIdFor, assertChatMembership} from "./chat_membership.js";

const fail = (msg, status = 400) => {
  throw Object.assign(new Error(msg), {status});
};
const validKey = value => typeof value === "string" &&
  /^[A-Za-z0-9_-]{12,100}$/.test(value);
const friendPath = (db, owner, peer) =>
  db.collection("users").doc(owner).collection("following").doc(peer);

/**
 * Only verified two-member conversations can be created. This backend is
 * distinct from Cloudflare's free Agora TOKEN Worker; deploy and connect the
 * authenticated economy backend before enabling the chat UI.
 */
export function registerChatRoutes({app, db, authenticatedUser}) {
  app.post("/chat/start", async (req, res, next) => {
    try {
      const sender = await authenticatedUser(req);
      const peer = String(req.body?.recipientId || "").trim();
      const id = chatIdFor(sender.uid, peer);
      const chatRef = db.collection("chats").doc(id);
      const senderRef = db.collection("users").doc(sender.uid);
      const peerRef = db.collection("users").doc(peer);
      const senderFollow = friendPath(db, sender.uid, peer);
      const peerFollow = friendPath(db, peer, sender.uid);
      const result = await db.runTransaction(async tx => {
        const [old, a, b, followsA, followsB] = await Promise.all(
          [chatRef, senderRef, peerRef, senderFollow, peerFollow].map(r => tx.get(r)),
        );
        if (!a.exists || !b.exists || !followsA.exists || !followsB.exists) {
          fail("Both participants must follow each other.", 403);
        }
        if (old.exists) {
          assertChatMembership(old.data(), sender.uid, peer);
          return {chatId: id, alreadyCreated: true};
        }
        tx.create(chatRef, {
          memberIds: [sender.uid, peer].sort(),
          memberNames: {
            [sender.uid]: String(a.data()?.displayName || "WorldVoice member"),
            [peer]: String(b.data()?.displayName || "WorldVoice member"),
          },
          active: true,
          latestText: null,
          lastMessageAt: FieldValue.serverTimestamp(),
          createdAt: FieldValue.serverTimestamp(),
        });
        return {chatId: id, alreadyCreated: false};
      });
      res.json({ok: true, ...result});
    } catch (error) { next(error); }
  });

  app.post("/chat/message", async (req, res, next) => {
    try {
      const sender = await authenticatedUser(req);
      const id = String(req.body?.chatId || "");
      const text = String(req.body?.text || "").trim();
      const rawKey = req.headers["idempotency-key"];
      if (!/^[a-f0-9]{64}$/.test(id) || text.length < 1 ||
          text.length > 1500 || !validKey(rawKey)) {
        fail("Invalid chat message or idempotency key.", 400);
      }
      const eventId = createHash("sha256")
        .update("worldvoice:chat:message:" + sender.uid + ":" + id + ":" + rawKey)
        .digest("hex");
      const chatRef = db.collection("chats").doc(id);
      const messageRef = chatRef.collection("messages").doc(eventId);
      const result = await db.runTransaction(async tx => {
        const [chat, old] = await Promise.all(
          [chatRef, messageRef].map(ref => tx.get(ref)),
        );
        const members = chat.data()?.memberIds;
        const peer = Array.isArray(members)
          ? members.find(uid => uid !== sender.uid) : null;
        if (!chat.exists || !peer) fail("Chat unavailable.", 403);
        assertChatMembership(chat.data(), sender.uid, peer);
        const a = friendPath(db, sender.uid, peer);
        const b = friendPath(db, peer, sender.uid);
        const [followsA, followsB] =
          await Promise.all([tx.get(a), tx.get(b)]);
        if (!followsA.exists || !followsB.exists) {
          fail("Messaging requires mutual following.", 403);
        }
        if (old.exists) {
          const prev = old.data() || {};
          if (prev.senderId !== sender.uid || prev.text !== text ||
              prev.type !== "text") fail("Idempotency key reused.", 409);
          return {messageId: eventId, alreadyProcessed: true};
        }
        tx.create(messageRef, {
          type: "text", senderId: sender.uid, text,
          senderName: String(chat.data().memberNames?.[sender.uid] || "Member"),
          createdAt: FieldValue.serverTimestamp(),
        });
        tx.update(chatRef, {
          latestText: text,
          lastMessageAt: FieldValue.serverTimestamp(),
        });
        return {messageId: eventId, alreadyProcessed: false};
      });
      res.json({ok: true, ...result});
    } catch (error) { next(error); }
  });
}
