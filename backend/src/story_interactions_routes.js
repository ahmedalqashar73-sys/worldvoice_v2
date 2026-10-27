// Private Story reactions and notifications. Only this signed-in API may write
// event documents; clients never receive unrestricted Firestore collection access.
import {createHash, randomUUID} from "node:crypto";
import {Timestamp} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

const MAX_COMMENT = 350;
function invalid(message, status = 400) {
  const e = new Error(message);
  e.status = status;
  throw e;
}
function storyIdFrom(value) {
  const id = String(value || "").trim();
  if (!/^[a-f0-9]{32}$|^[a-f0-9]{64}$/.test(id)) invalid("Invalid story ID.");
  return id;
}
function safe(value, length = 100) {
  return String(value || "").trim().slice(0, length);
}
async function storyAccess(db, id, viewerId) {
  const ref = db.collection("stories").doc(id);
  const snap = await ref.get();
  if (!snap.exists) invalid("Story not found.", 404);
  const data = snap.data() || {};
  if ((data.expiresAt?.toMillis?.() || 0) <= Date.now()) {
    invalid("Story has expired.", 410);
  }
  const ownerId = safe(data.ownerId, 150);
  if (!ownerId) invalid("Story has no owner.", 404);
  if (viewerId !== ownerId) {
    const [blockedByOwner, blockedByViewer] = await Promise.all([
      db.collection("users").doc(ownerId).collection("blocked_peers").doc(viewerId).get(),
      db.collection("users").doc(viewerId).collection("blocked_peers").doc(ownerId).get(),
    ]);
    if (blockedByOwner.exists || blockedByViewer.exists) {
      invalid("Story is not available.", 403);
    }
    if (data.audience === "close_friends") {
      const friend = await db.collection("users").doc(ownerId)
        .collection("close_friends").doc(viewerId).get();
      if (!friend.exists) invalid("Story is for Close Friends only.", 403);
    } else if (data.audience !== "everyone") {
      invalid("Story is not available.", 403);
    }
  }
  return {ref, data, ownerId};
}
async function viewerInfo(db, user) {
  const profile = await db.collection("users").doc(user.uid).get();
  return {
    uid: user.uid,
    displayName: safe(profile.data()?.displayName || profile.data()?.name ||
      user.name || "WorldVoice"),
    photoUrl: safe(profile.data()?.photoUrl || user.picture, 600),
  };
}
async function sendStoryPush(db, ownerId, kind, actor) {
  try {
    const profile = await db.collection("users").doc(ownerId).get();
    if (profile.data()?.storyNotificationsEnabled === false) return;
    const [mainDevices, storyDevices] = await Promise.all([
      db.collection("users").doc(ownerId).collection("notification_devices")
        .limit(10).get(),
      db.collection("users").doc(ownerId).collection("story_notification_devices")
        .limit(10).get(),
    ]);
    const tokens = [...new Set([
      ...mainDevices.docs.map(d => d.data()?.token),
      ...storyDevices.docs.map(d => d.data()?.token),
    ].filter(Boolean))].slice(0, 10);
    if (!tokens.length) return;
    const ar = profile.data()?.notificationLanguageCode === "ar";
    await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: ar ? "تفاعل جديد على الستوري" : "New Story activity",
        body: kind === "like"
          ? (ar ? `${actor.displayName} أعجب بالستوري` : `${actor.displayName} liked your Story`)
          : (ar ? `${actor.displayName} علّق على الستوري` : `${actor.displayName} commented on your Story`),
      },
      data: {type: "story_interaction", inbox: "story", kind},
      android: {priority: "high"},
    });
  } catch (error) {
    // A push failure must never roll back a successfully stored like/comment.
    console.warn("Story notification push unavailable:", error?.code || error?.message);
  }
}
export function registerStoryInteractionRoutes({app, authenticatedUser, db}) {
  // Story pushes work independently even if the legacy social backend has not
  // deployed its FCM device registration route.
  app.post("/stories/notifications/register-device", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const token = safe(req.body?.token, 2049);
      if (token.length < 30 || token.length > 2048) {
        invalid("Invalid push token.");
      }
      const tokenId = createHash("sha256").update(token).digest("hex");
      const ownerRef = db.collection("story_notification_token_owners").doc(tokenId);
      const deviceRef = db.collection("users").doc(user.uid)
        .collection("story_notification_devices").doc(tokenId);
      await db.runTransaction(async tx => {
        const previous = await tx.get(ownerRef);
        const oldOwnerId = previous.data()?.uid;
        if (oldOwnerId && oldOwnerId !== user.uid) {
          tx.delete(db.collection("users").doc(oldOwnerId)
            .collection("story_notification_devices").doc(tokenId));
        }
        tx.set(ownerRef, {uid: user.uid, updatedAt: Timestamp.now()});
        tx.set(deviceRef, {token, updatedAt: Timestamp.now()});
      });
      return res.json({ok: true});
    } catch (e) { next(e); }
  });

  app.get("/stories/preferences", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const profile = await db.collection("users").doc(user.uid).get();
      return res.json({ok: true,
        allowReplies: profile.data()?.storyRepliesEnabled !== false,
        notifyActivity: profile.data()?.storyNotificationsEnabled !== false,
      });
    } catch (e) { next(e); }
  });
  app.post("/stories/preferences", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const allowReplies = req.body?.allowReplies;
      const notifyActivity = req.body?.notifyActivity;
      if (typeof allowReplies !== "boolean" ||
          typeof notifyActivity !== "boolean") {
        invalid("Story preferences must be booleans.");
      }
      await db.collection("users").doc(user.uid).set({
        storyRepliesEnabled: allowReplies,
        storyNotificationsEnabled: notifyActivity,
      }, {merge: true});
      res.json({ok: true, allowReplies, notifyActivity});
    } catch (e) { next(e); }
  });
  app.get("/stories/interactions", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const {ref, ownerId} = await storyAccess(db, storyIdFrom(req.query.storyId), user.uid);
      const likes = ref.collection("likes");
      const comments = ref.collection("comments");
      const [mine, likeCount, commentCount, likeList, commentList, settings] =
        await Promise.all([
          likes.doc(user.uid).get(),
          likes.count().get(),
          comments.count().get(),
          user.uid === ownerId ? likes.orderBy("createdAt", "desc").limit(60).get() : Promise.resolve(null),
          user.uid === ownerId ? comments.orderBy("createdAt", "desc").limit(60).get() : Promise.resolve(null),
          db.collection("users").doc(ownerId).get(),
        ]);
      return res.json({ok: true,
        liked: mine.exists,
        likesCount: likeCount.data().count,
        commentsCount: commentCount.data().count,
        allowReplies: settings.data()?.storyRepliesEnabled !== false,
        likes: likeList ? likeList.docs.map(d => d.data()) : [],
        comments: commentList ? commentList.docs.map(d => ({id: d.id, ...d.data(),
          createdAt: d.data().createdAt?.toMillis?.() || 0})) : [],
      });
    } catch (e) { next(e); }
  });
  app.post("/stories/like", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const storyId = storyIdFrom(req.body?.storyId);
      const {ref, ownerId} = await storyAccess(db, storyId, user.uid);
      if (ownerId === user.uid) invalid("You cannot like your own Story.");
      if (typeof req.body?.liked !== "boolean") invalid("liked must be a boolean.");
      const likeRef = ref.collection("likes").doc(user.uid);
      if (req.body.liked) {
        const actor = await viewerInfo(db, user);
        const created = await db.runTransaction(async tx => {
          const previous = await tx.get(likeRef);
          if (previous.exists) return false;
          tx.create(likeRef, {...actor, createdAt: Timestamp.now()});
          tx.set(db.collection("users").doc(ownerId).collection("story_notifications")
            .doc(`${storyId}_like_${user.uid}`), {
              storyId, type: "like", actorId: user.uid,
              actorName: actor.displayName, actorPhotoUrl: actor.photoUrl,
              createdAt: Timestamp.now(), read: false,
            });
          return true;
        });
        if (created) await sendStoryPush(db, ownerId, "like", actor);
      } else {
        await likeRef.delete();
      }
      return res.json({ok: true, liked: req.body.liked});
    } catch (e) { next(e); }
  });
  app.post("/stories/comment", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const storyId = storyIdFrom(req.body?.storyId);
      const {ref, ownerId} = await storyAccess(db, storyId, user.uid);
      if (ownerId === user.uid) invalid("Cannot comment on your own Story.");
      const text = safe(req.body?.text, MAX_COMMENT + 1);
      if (!text || text.length > MAX_COMMENT) {
        invalid("Comment must contain 1 to 350 characters.");
      }
      const ownerProfile = await db.collection("users").doc(ownerId).get();
      if (ownerProfile.data()?.storyRepliesEnabled === false) {
        invalid("Story owner has disabled replies and comments.", 403);
      }
      const previous = await ref.collection("comments").where("uid", "==", user.uid)
        .limit(20).get();
      if (previous.size >= 20) invalid("Too many comments on this Story.", 429);
      const actor = await viewerInfo(db, user);
      const id = randomUUID().replaceAll("-", "");
      const now = Timestamp.now();
      const batch = db.batch();
      batch.create(ref.collection("comments").doc(id), {...actor, text, createdAt: now});
      batch.create(db.collection("users").doc(ownerId)
        .collection("story_notifications").doc(`${storyId}_comment_${id}`), {
          storyId, type: "comment", actorId: user.uid,
          actorName: actor.displayName, actorPhotoUrl: actor.photoUrl,
          text, createdAt: now, read: false,
        });
      await batch.commit();
      await sendStoryPush(db, ownerId, "comment", actor);
      res.json({ok: true, commentId: id});
    } catch (e) { next(e); }
  });
  app.get("/stories/notifications", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const events = await db.collection("users").doc(user.uid)
        .collection("story_notifications")
        .orderBy("createdAt", "desc").limit(60).get();
      res.json({ok: true, events: events.docs.map(d => ({id: d.id,
        ...d.data(), createdAt: d.data().createdAt?.toMillis?.() || 0}))});
    } catch (e) { next(e); }
  });
}
