import {FieldValue} from "firebase-admin/firestore";

const validId = value => typeof value === "string" &&
  /^[A-Za-z0-9_-]{8,160}$/.test(value);
const fail = (reason, http = 400) => {
  const error = new Error(reason);
  error.status = http;
  throw error;
};
const roleOf = (group, uid) => group.ownerId === uid
  ? "owner" : (group.moderatorIds || []).includes(uid)
    ? "moderator" : "member";
const inGroup = (group, uid) =>
  group.type === "group" && group.active !== false &&
  Array.isArray(group.memberIds) && group.memberIds.includes(uid);
const unique = items => [...new Set(items)];


/** Group message changes are server-authoritative, never Firestore client writes. */
export function canManageGroupMessage(group, message, actorId, action) {
  const activeMember = inGroup(group, actorId);
  if (!activeMember || message.deleted === true) return false;
  if (action === "edit" || action === "replace_audio") {
    return message.senderId === actorId &&
      message.type === (action === "edit" ? "text" : "audio");
  }
  return action === "delete" &&
    (message.senderId === actorId || roleOf(group, actorId) !== "member");
}

function verifiedAudioUpload(url) {
  try {
    const value = new URL(url);
    return value.protocol === "https:" && value.hostname === "res.cloudinary.com" &&
      value.pathname.startsWith("/ypmmcyxm/video/upload/");
  } catch (_) {
    return false;
  }
}

export function registerGroupManagementRoutes({app, db, authenticatedUser}) {
  app.post("/chat/group/manage", async (req, res, next) => {
    try {
      const actor = await authenticatedUser(req);
      const chatId = String(req.body?.chatId || "");
      const action = String(req.body?.action || "");
      const targetId = String(req.body?.targetId || "");
      if (!validId(chatId) ||
          !["leave", "add", "remove", "promote", "demote",
            "delete_for_me", "delete_group"].includes(action)) {
        fail("Invalid group operation.");
      }
      if (["add","remove","promote","demote"].includes(action) &&
          !validId(targetId)) fail("Choose a valid group member.");
      const chatRef = db.collection("chats").doc(chatId);
      const result = await db.runTransaction(async tx => {
        const snap = await tx.get(chatRef);
        const group = snap.data() || {};
        const retryOwnerDelete = action === "delete_group" &&
            group.type === "group" && group.ownerId === actor.uid &&
            group.active === false;
        if (!snap.exists ||
            (!inGroup(group, actor.uid) && !retryOwnerDelete)) {
          fail("You are not an active group member.", 403);
        }
        const role = roleOf(group, actor.uid);
        const members = group.memberIds;
        const mods = group.moderatorIds || [];
        if (action === "delete_for_me") {
          // This is a private inbox preference, never a group deletion.
          tx.set(db.collection("users").doc(actor.uid), {
            hiddenGroupChatIds: FieldValue.arrayUnion(chatId),
          }, {merge:true});
          return {action, hidden:true};
        }
        if (action === "delete_group") {
          if (role !== "owner") fail("Only the creator may delete a group.", 403);
          if (!retryOwnerDelete) {
            // Deny new reads and writes immediately, before the recursive
            // purge. Retain ownership for secure retries if purge fails.
            tx.update(chatRef, {
              active:false, memberIds:[], moderatorIds:[],
              deletedAt:FieldValue.serverTimestamp(),
            });
          }
          return {action, deleted:true};
        }
        if (action === "leave") {
          if (role === "owner") {
            fail("The creator must transfer ownership or delete the group.", 409);
          }
          tx.update(chatRef, {
            memberIds:FieldValue.arrayRemove(actor.uid),
            moderatorIds:FieldValue.arrayRemove(actor.uid),
            updatedAt:FieldValue.serverTimestamp(),
          });
          return {action, left:true};
        }
        if (role === "member") fail("Group moderation requires permission.", 403);
        if (action === "add") {
          if (members.includes(targetId)) return {action, alreadyMember:true};
          if (members.length >= 30) fail("Group has reached 30 members.", 409);
          const profile = await tx.get(db.collection("users").doc(targetId));
          if (!profile.exists) fail("User profile unavailable.", 404);
          // Don't add blocked users to groups. Preserve the creator's
          // mutual-follow privacy rule for all later group additions.
          const [follows, followsBack, blockA, blockB] = await Promise.all([
            tx.get(db.collection("users").doc(group.ownerId).collection("following").doc(targetId)),
            tx.get(db.collection("users").doc(targetId).collection("following").doc(group.ownerId)),
            tx.get(db.collection("users").doc(group.ownerId).collection("blocked_peers").doc(targetId)),
            tx.get(db.collection("users").doc(targetId).collection("blocked_peers").doc(group.ownerId)),
          ]);
          if (!follows.exists || !followsBack.exists || blockA.exists || blockB.exists) {
            fail("Adding this user requires mutual following and no block.",403);
          }
          const profileData = profile.data() || {};
          tx.update(chatRef, {
            memberIds:FieldValue.arrayUnion(targetId),
            [`memberNames.${targetId}`]:
              String(profileData.displayName || profileData.name || "WorldVoice member"),
            [`memberPhotos.${targetId}`]: String(profileData.photoUrl || ""),
            updatedAt:FieldValue.serverTimestamp(),
          });
          return {action, added:true};
        }
        if (!members.includes(targetId)) fail("Target is not in this group.",409);
        if (targetId === group.ownerId) fail("Cannot modify the creator.",403);
        if (action === "remove") {
          if (role !== "owner" && mods.includes(targetId)) {
            fail("Moderators cannot remove another moderator.", 403);
          }
          tx.update(chatRef, {
            memberIds:FieldValue.arrayRemove(targetId),
            moderatorIds:FieldValue.arrayRemove(targetId),
            updatedAt:FieldValue.serverTimestamp(),
          });
          return {action, removed:true};
        }
        if (role !== "owner") fail("Only the creator can change moderators.",403);
        tx.update(chatRef, {
          moderatorIds:action === "promote"
            ? FieldValue.arrayUnion(targetId)
            : FieldValue.arrayRemove(targetId),
          updatedAt:FieldValue.serverTimestamp(),
        });
        return {action, moderator:action === "promote"};
      });
      if (action === "delete_group") {
        // Clear the chat document and messages, not just the owner's list.
        // A failed purge leaves a no-access tombstone which only the owner
        // can retry. Uploaded media on third-party CDNs is a separate
        // retention concern and is not represented as purged here.
        await db.recursiveDelete(chatRef);
      }
      res.json({ok:true, ...result});
    } catch (error) {next(error);}
  });

  // Edit own text, replace own voice clip, or remove a message for all group members.
  // Deletions retain only a content-free tombstone for timeline consistency.
  app.post("/chat/group/message/manage", async (req, res, next) => {
    try {
      const actor = await authenticatedUser(req);
      const chatId = String(req.body?.chatId || "");
      const messageId = String(req.body?.messageId || "");
      const action = String(req.body?.action || "");
      const text = String(req.body?.text || "").trim();
      const mediaUrl = String(req.body?.mediaUrl || "").trim();
      const mediaPublicId = String(req.body?.mediaPublicId || "").trim();
      const fileName = String(req.body?.fileName || "").split(/[\\/]/).pop();
      const fileSize = Number(req.body?.fileSize || 0);
      if (!validId(chatId) || !validId(messageId) ||
          !["edit", "delete", "replace_audio"].includes(action)) {
        fail("Invalid group message operation.");
      }
      if (action === "edit" && (text.length < 1 || text.length > 1500)) {
        fail("A message must contain 1 to 1500 characters.");
      }
      if (action === "replace_audio" &&
          (!verifiedAudioUpload(mediaUrl) ||
           !/^[a-zA-Z0-9_\\/.-]{1,250}$/.test(mediaPublicId) ||
           !fileName || fileName.length > 120 ||
           !Number.isSafeInteger(fileSize) || fileSize < 1 ||
           fileSize > 20 * 1024 * 1024)) {
        fail("Invalid replacement voice recording.");
      }

      const chatRef = db.collection("chats").doc(chatId);
      const messageRef = chatRef.collection("messages").doc(messageId);
      const result = await db.runTransaction(async tx => {
        const [chatSnap, messageSnap] = await Promise.all([
          tx.get(chatRef), tx.get(messageRef),
        ]);
        if (!chatSnap.exists || !messageSnap.exists) {
          fail("Group message unavailable.", 404);
        }
        const group = chatSnap.data() || {};
        const message = messageSnap.data() || {};
        if (!inGroup(group, actor.uid)) {
          fail("Only active group members can manage messages.", 403);
        }
        if (action === "delete" && message.deleted === true) {
          // A repeated delete is safe for the original sender or moderators.
          if (message.senderId !== actor.uid &&
              roleOf(group, actor.uid) === "member") {
            fail("You cannot delete another member's message.", 403);
          }
          return {action, alreadyDeleted:true};
        }
        if (!canManageGroupMessage(group, message, actor.uid, action)) {
          fail("You do not have permission to change this message.", 403);
        }
        if (action === "edit") {
          tx.update(messageRef, {
            text, edited:true, editedAt:FieldValue.serverTimestamp(),
          });
          if (group.latestText === message.text) {
            tx.update(chatRef, {latestText:text});
          }
        } else if (action === "replace_audio") {
          tx.update(messageRef, {
            mediaUrl, mediaPublicId, fileName, fileSize,
            edited:true, editedAt:FieldValue.serverTimestamp(),
          });
        } else {
          const preview = message.type === "text" ? message.text :
            ({image:"📷 Photo", video:"🎬 Video", audio:"🎙 Voice message",
              pdf:"📄 PDF"})[message.type];
          tx.update(messageRef, {
            type:"deleted", deleted:true, deletedAt:FieldValue.serverTimestamp(),
            text:FieldValue.delete(), mediaUrl:FieldValue.delete(),
            mediaPublicId:FieldValue.delete(), fileName:FieldValue.delete(),
            fileSize:FieldValue.delete(),
          });
          if (preview && group.latestText === preview) {
            tx.update(chatRef, {latestText:"🗑 Message deleted"});
          }
        }
        return {action, messageId, updated:true};
      });
      res.json({ok:true, ...result});
    } catch (error) { next(error); }
  });

}
