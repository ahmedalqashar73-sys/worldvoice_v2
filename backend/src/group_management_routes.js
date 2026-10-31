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
        if (!snap.exists || !inGroup(snap.data() || {}, actor.uid)) {
          fail("You are not an active group member.", 403);
        }
        const group = snap.data();
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
          // Tombstone immediately. Backend purges child messages separately;
          // never expose data again via chat rules or group member queries.
          tx.update(chatRef, {
            active:false, memberIds:[], moderatorIds:[],
            deletedAt:FieldValue.serverTimestamp(),
          });
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
      // Never claim to have physically erased child messages: the tombstone
      // denies membership reads, while history retention follows app policy.
      res.json({ok:true, ...result});
    } catch (error) {next(error);}
  });
}
