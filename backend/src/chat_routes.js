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

function assertSenderInChat(data, senderId) {
  if (data?.active !== true ||
      !Array.isArray(data.memberIds) ||
      data.memberIds.length < 2 ||
      data.memberIds.length > 32 ||
      !data.memberIds.includes(senderId) ||
      data.memberIds.some(id => typeof id !== "string")) {
    fail("Verified chat membership required.", 403);
  }
}

function validCloudinaryMedia(url) {
  try {
    const parsed = new URL(String(url || ""));
    return parsed.protocol === "https:" &&
      parsed.hostname === "res.cloudinary.com" &&
      parsed.pathname.startsWith("/ypmmcyxm/");
  } catch (_) {
    return false;
  }
}

function normalizedMediaType(value) {
  return value === "image" || value === "video" ? value : "";
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

  app.post("/chat/group/create", async (req, res, next) => {
    try {
      const creator = await authenticatedUser(req);
      const name = String(req.body?.name || "").trim();
      const rawMembers = Array.isArray(req.body?.memberIds)
        ? req.body.memberIds : [];
      const memberIds = [...new Set(
        rawMembers
          .map(value => String(value || "").trim())
          .filter(value => value && value !== creator.uid),
      )];

      if (!name || name.length > 80) {
        fail("Group name must be between 1 and 80 characters.");
      }
      if (memberIds.length < 2 || memberIds.length > 29) {
        fail("Choose between 2 and 29 other members.");
      }

      const creatorRef = db.collection("users").doc(creator.uid);
      const memberRefs = memberIds.map(id => db.collection("users").doc(id));
      const relationshipRefs = memberIds.flatMap(id => [
        creatorRef.collection("following").doc(id),
        db.collection("users").doc(id).collection("following").doc(creator.uid),
      ]);
      const [creatorSnap, ...rest] = await db.getAll(
        creatorRef,
        ...memberRefs,
        ...relationshipRefs,
      );
      const profileSnaps = rest.slice(0, memberRefs.length);
      const relationshipSnaps = rest.slice(memberRefs.length);

      if (!creatorSnap.exists || profileSnaps.some(snap => !snap.exists)) {
        fail("A selected WorldVoice profile is unavailable.", 404);
      }
      if (relationshipSnaps.some(snap => !snap.exists)) {
        fail("Group members must mutually follow the creator.", 403);
      }

      const allIds = [creator.uid, ...memberIds];
      const names = {
        [creator.uid]: String(
          creatorSnap.data()?.displayName ||
          creator.name ||
          "WorldVoice member",
        ),
      };
      for (const snap of profileSnaps) {
        names[snap.id] = String(
          snap.data()?.displayName || snap.data()?.name || "WorldVoice member",
        );
      }

      const chatRef = db.collection("chats").doc();
      await chatRef.set({
        type: "group",
        groupName: name,
        ownerId: creator.uid,
        memberIds: allIds,
        memberNames: names,
        active: true,
        latestText: null,
        lastMessageAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      res.json({
        ok: true,
        chatId: chatRef.id,
        groupName: name,
        memberIds: allIds,
      });
    } catch (error) { next(error); }
  });

  app.post("/chat/media", async (req, res, next) => {
    try {
      const sender = await authenticatedUser(req);
      const id = String(req.body?.chatId || "");
      const type = normalizedMediaType(String(req.body?.mediaType || ""));
      const mediaUrl = String(req.body?.mediaUrl || "").trim();
      const mediaPublicId = String(req.body?.mediaPublicId || "").trim();
      const rawKey = req.headers["idempotency-key"];

      if (!/^[A-Za-z0-9_-]{8,160}$/.test(id) ||
          !type ||
          !validCloudinaryMedia(mediaUrl) ||
          !validKey(rawKey)) {
        fail("Invalid chat media.", 400);
      }

      const eventId = createHash("sha256")
        .update("worldvoice:chat:media:" + sender.uid + ":" + id + ":" + rawKey)
        .digest("hex");
      const chatRef = db.collection("chats").doc(id);
      const messageRef = chatRef.collection("messages").doc(eventId);

      const result = await db.runTransaction(async tx => {
        const [chatSnap, old] = await Promise.all([
          tx.get(chatRef),
          tx.get(messageRef),
        ]);
        if (!chatSnap.exists) fail("Chat unavailable.", 403);
        const chat = chatSnap.data() || {};
        assertSenderInChat(chat, sender.uid);

        if (old.exists) {
          const previous = old.data() || {};
          if (previous.senderId !== sender.uid ||
              previous.mediaUrl !== mediaUrl ||
              previous.type !== type) {
            fail("Idempotency key reused.", 409);
          }
          return {messageId: eventId, alreadyProcessed: true};
        }

        tx.create(messageRef, {
          type,
          senderId: sender.uid,
          senderName: String(chat.memberNames?.[sender.uid] || "Member"),
          mediaUrl,
          mediaPublicId,
          createdAt: FieldValue.serverTimestamp(),
        });
        tx.update(chatRef, {
          latestText: type === "image" ? "📷 Photo" : "🎬 Video",
          lastMessageAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        return {messageId: eventId, alreadyProcessed: false};
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
        if (!chat.exists) fail("Chat unavailable.", 403);
        const chatData = chat.data() || {};
        const members = chatData.memberIds;
        const peer = Array.isArray(members)
          ? members.find(uid => uid !== sender.uid) : null;
        if (chatData.type === "group") {
          assertSenderInChat(chatData, sender.uid);
        } else {
          if (!peer) fail("Chat unavailable.", 403);
          assertChatMembership(chatData, sender.uid, peer);
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
