import {createHash} from "node:crypto";
import {FieldValue} from "firebase-admin/firestore";
import {chatIdFor, assertChatMembership} from "./chat_membership.js";

const fail = (msg, status = 400) => {
  throw Object.assign(new Error(msg), {status});
};
const validKey = value => typeof value === "string" &&
  /^[A-Za-z0-9_-]{12,100}$/.test(value);

const requestIdFor = (senderUid, recipientUid) =>
  createHash("sha256")
    .update("worldvoice:message-request:" + senderUid + ":" + recipientUid)
    .digest("hex");

function directChatPayload(sender, peer, senderData, peerData) {
  return {
    memberIds: [sender.uid, peer].sort(),
    memberNames: {
      [sender.uid]: String(
        senderData?.displayName || sender.name || "WorldVoice member",
      ),
      [peer]: String(peerData?.displayName || "WorldVoice member"),
    },
    active: true,
    latestText: null,
    lastMessageAt: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(),
  };
}

/**
 * Direct messaging is server-authoritative. Users may optionally require
 * approval before a NEW direct conversation can be opened. Existing chats
 * continue to work after the privacy switch is enabled.
 */
export function registerChatRoutes({app, db, authenticatedUser}) {
  app.post("/chat/privacy", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const required = req.body?.messageApprovalRequired === true;
      await db.collection("users").doc(user.uid).set({
        messageApprovalRequired: required,
        messagePrivacyUpdatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      res.json({ok: true, messageApprovalRequired: required});
    } catch (error) { next(error); }
  });

  app.get("/chat/requests", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const snapshot = await db
        .collection("message_requests")
        .where("recipientId", "==", user.uid)
        .limit(100)
        .get();

      const requests = snapshot.docs
        .filter(doc => doc.data()?.status === "pending")
        .map(doc => {
          const data = doc.data() || {};
          return {
            id: doc.id,
            senderId: String(data.senderId || ""),
            senderName: String(data.senderName || "WorldVoice member"),
            senderPhotoUrl: String(data.senderPhotoUrl || ""),
            createdAtMs: data.createdAt?.toMillis?.() || 0,
          };
        })
        .sort((a, b) => b.createdAtMs - a.createdAtMs);

      res.json({ok: true, requests});
    } catch (error) { next(error); }
  });

  app.post("/chat/request/respond", async (req, res, next) => {
    try {
      const recipient = await authenticatedUser(req);
      const requestId = String(req.body?.requestId || "").trim();
      const action = String(req.body?.action || "").trim();
      if (!/^[a-f0-9]{64}$/.test(requestId) ||
          !["accept", "decline"].includes(action)) {
        fail("Invalid message request response.", 400);
      }

      const requestRef = db.collection("message_requests").doc(requestId);
      const result = await db.runTransaction(async tx => {
        const requestSnap = await tx.get(requestRef);
        if (!requestSnap.exists) fail("Message request not found.", 404);
        const request = requestSnap.data() || {};
        if (request.recipientId !== recipient.uid) {
          fail("This message request belongs to another account.", 403);
        }
        if (request.status !== "pending") {
          return {
            status: String(request.status || "unknown"),
            chatId: request.chatId || null,
            alreadyProcessed: true,
          };
        }

        if (action === "decline") {
          tx.update(requestRef, {
            status: "declined",
            respondedAt: FieldValue.serverTimestamp(),
          });
          return {
            status: "declined",
            chatId: null,
            alreadyProcessed: false,
          };
        }

        const senderId = String(request.senderId || "");
        if (!senderId) fail("Message request sender is unavailable.", 409);
        const chatId = chatIdFor(senderId, recipient.uid);
        const chatRef = db.collection("chats").doc(chatId);
        const senderRef = db.collection("users").doc(senderId);
        const recipientRef = db.collection("users").doc(recipient.uid);
        const [chatSnap, senderSnap, recipientSnap] = await Promise.all([
          tx.get(chatRef),
          tx.get(senderRef),
          tx.get(recipientRef),
        ]);
        if (!senderSnap.exists || !recipientSnap.exists) {
          fail("WorldVoice profile is unavailable.", 404);
        }

        if (!chatSnap.exists) {
          tx.create(
            chatRef,
            directChatPayload(
              {uid: senderId},
              recipient.uid,
              senderSnap.data(),
              recipientSnap.data(),
            ),
          );
        } else {
          assertChatMembership(chatSnap.data(), senderId, recipient.uid);
        }

        tx.update(requestRef, {
          status: "accepted",
          chatId,
          respondedAt: FieldValue.serverTimestamp(),
        });
        return {
          status: "accepted",
          chatId,
          alreadyProcessed: false,
          senderId,
          senderName: String(
            senderSnap.data()?.displayName || "WorldVoice member",
          ),
        };
      });

      res.json({ok: true, ...result});
    } catch (error) { next(error); }
  });

  app.post("/chat/start", async (req, res, next) => {
    try {
      const sender = await authenticatedUser(req);
      const peer = String(req.body?.recipientId || "").trim();
      if (!peer || peer === sender.uid) {
        fail("Choose another WorldVoice member.", 400);
      }

      const id = chatIdFor(sender.uid, peer);
      const chatRef = db.collection("chats").doc(id);
      const senderRef = db.collection("users").doc(sender.uid);
      const peerRef = db.collection("users").doc(peer);
      const messageRequestId = requestIdFor(sender.uid, peer);
      const requestRef = db.collection("message_requests").doc(messageRequestId);

      const result = await db.runTransaction(async tx => {
        const [old, senderSnap, peerSnap] = await Promise.all(
          [chatRef, senderRef, peerRef].map(ref => tx.get(ref)),
        );
        if (!senderSnap.exists || !peerSnap.exists) {
          fail("Both WorldVoice profiles must exist.", 404);
        }

        if (old.exists) {
          assertChatMembership(old.data(), sender.uid, peer);
          return {
            chatId: id,
            alreadyCreated: true,
            status: "ready",
          };
        }

        const approvalRequired =
          peerSnap.data()?.messageApprovalRequired === true;
        if (approvalRequired) {
          const requestSnap = await tx.get(requestRef);
          if (requestSnap.exists) {
            const request = requestSnap.data() || {};
            if (request.status === "accepted") {
              tx.create(
                chatRef,
                directChatPayload(
                  sender,
                  peer,
                  senderSnap.data(),
                  peerSnap.data(),
                ),
              );
              return {
                chatId: id,
                alreadyCreated: false,
                status: "ready",
              };
            }
            if (request.status === "declined") {
              return {
                chatId: null,
                requestId: messageRequestId,
                status: "request_declined",
              };
            }
            return {
              chatId: null,
              requestId: messageRequestId,
              status: "request_pending",
            };
          }

          tx.create(requestRef, {
            senderId: sender.uid,
            senderName: String(
              senderSnap.data()?.displayName ||
              sender.name ||
              "WorldVoice member",
            ),
            senderPhotoUrl: String(senderSnap.data()?.photoUrl || ""),
            recipientId: peer,
            recipientName: String(
              peerSnap.data()?.displayName || "WorldVoice member",
            ),
            status: "pending",
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });
          return {
            chatId: null,
            requestId: messageRequestId,
            status: "request_pending",
          };
        }

        tx.create(
          chatRef,
          directChatPayload(
            sender,
            peer,
            senderSnap.data(),
            peerSnap.data(),
          ),
        );
        return {
          chatId: id,
          alreadyCreated: false,
          status: "ready",
        };
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
