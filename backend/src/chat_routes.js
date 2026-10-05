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
 * Only verified two-member conversations can be created. A signed-in member
 * may start a direct conversation with another existing WorldVoice member.
 * Firestore clients still cannot forge memberships or write chat messages.
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
      const requestRef = peerRef.collection("message_requests").doc(sender.uid);

      const result = await db.runTransaction(async tx => {
        const [old, a, b, request] = await Promise.all(
          [chatRef, senderRef, peerRef, requestRef].map(ref => tx.get(ref)),
        );
        if (!a.exists || !b.exists) {
          fail("Both WorldVoice profiles must exist.", 404);
        }
        if (old.exists) {
          assertChatMembership(old.data(), sender.uid, peer);
          return {chatId: id, alreadyCreated: true};
        }

        const peerData = b.data() || {};
        const approvalRequired = peerData.messageApprovalRequired === true;
        if (approvalRequired) {
          const requestData = request.data() || {};
          const declinedUntil = requestData.declinedUntil;
          const declinedUntilMs =
            typeof declinedUntil?.toMillis === "function"
              ? declinedUntil.toMillis()
              : 0;
          if (
            request.exists &&
            requestData.status === "declined" &&
            declinedUntilMs > Date.now()
          ) {
            return {
              pendingApproval: true,
              requestCooldown: true,
              recipientId: peer,
            };
          }

          tx.set(requestRef, {
            requesterId: sender.uid,
            requesterName: String(
              a.data()?.displayName || a.data()?.name || "WorldVoice member",
            ),
            requesterPhotoUrl: String(a.data()?.photoUrl || ""),
            recipientId: peer,
            status: "pending",
            createdAt: request.exists
              ? requestData.createdAt || FieldValue.serverTimestamp()
              : FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
            declinedUntil: null,
          }, {merge: true});

          return {
            pendingApproval: true,
            requestCooldown: false,
            recipientId: peer,
          };
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

  app.post("/chat/requests/list", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const snapshot = await db
        .collection("users")
        .doc(user.uid)
        .collection("message_requests")
        .where("status", "==", "pending")
        .limit(100)
        .get();

      const requests = snapshot.docs
        .map(doc => {
          const data = doc.data() || {};
          const createdAt = data.createdAt;
          return {
            requesterId: String(data.requesterId || doc.id),
            requesterName: String(
              data.requesterName || "WorldVoice member",
            ),
            requesterPhotoUrl: String(data.requesterPhotoUrl || ""),
            createdAtMs: typeof createdAt?.toMillis === "function"
              ? createdAt.toMillis()
              : 0,
          };
        })
        .sort((a, b) => b.createdAtMs - a.createdAtMs);

      res.json({ok: true, requests});
    } catch (error) { next(error); }
  });

  app.post("/chat/request/respond", async (req, res, next) => {
    try {
      const recipient = await authenticatedUser(req);
      const requesterId = String(req.body?.requesterId || "").trim();
      const accept = req.body?.accept === true;
      const id = chatIdFor(recipient.uid, requesterId);
      const chatRef = db.collection("chats").doc(id);
      const recipientRef = db.collection("users").doc(recipient.uid);
      const requesterRef = db.collection("users").doc(requesterId);
      const requestRef = recipientRef
        .collection("message_requests")
        .doc(requesterId);

      const result = await db.runTransaction(async tx => {
        const [request, recipientProfile, requesterProfile, oldChat] =
          await Promise.all(
            [requestRef, recipientRef, requesterRef, chatRef]
              .map(ref => tx.get(ref)),
          );

        if (!request.exists || request.data()?.status !== "pending") {
          fail("Message request is no longer available.", 404);
        }
        if (!recipientProfile.exists || !requesterProfile.exists) {
          fail("WorldVoice profile is unavailable.", 404);
        }

        if (!accept) {
          const cooldown = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
          tx.set(requestRef, {
            status: "declined",
            respondedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
            declinedUntil: cooldown,
          }, {merge: true});
          return {accepted: false};
        }

        if (!oldChat.exists) {
          tx.create(chatRef, {
            memberIds: [recipient.uid, requesterId].sort(),
            memberNames: {
              [recipient.uid]: String(
                recipientProfile.data()?.displayName || "WorldVoice member",
              ),
              [requesterId]: String(
                requesterProfile.data()?.displayName || "WorldVoice member",
              ),
            },
            active: true,
            latestText: null,
            lastMessageAt: FieldValue.serverTimestamp(),
            createdAt: FieldValue.serverTimestamp(),
          });
        } else {
          assertChatMembership(oldChat.data(), recipient.uid, requesterId);
        }

        tx.set(requestRef, {
          status: "accepted",
          respondedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          declinedUntil: null,
        }, {merge: true});

        return {
          accepted: true,
          chatId: id,
          requesterId,
          requesterName: String(
            requesterProfile.data()?.displayName || "WorldVoice member",
          ),
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
