import {randomUUID} from "node:crypto";

import express from "express";
import {Timestamp} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";

const MAX_IMAGE_BYTES = 12 * 1024 * 1024;
const MAX_VIDEO_BYTES = 80 * 1024 * 1024;
const MAX_VIDEO_MS = 90 * 1000;
const STORY_LIFETIME_MS = 24 * 60 * 60 * 1000;
const SIGNED_URL_LIFETIME_MS = 15 * 60 * 1000;
const MAX_FEED_STORIES = 80;
const MAX_CLOSE_FRIENDS = 200;

function fail(message, status = 400) {
  const error = new Error(message);
  error.status = status;
  throw error;
}

function storyKind(value) {
  return value === "image" || value === "video" ? value : "";
}

function storyAudience(value) {
  return value === "everyone" || value === "close_friends" ? value : "";
}

function extensionFor(contentType, kind) {
  const normalized = String(contentType || "").toLowerCase();
  if (normalized.includes("png")) return "png";
  if (normalized.includes("webp")) return "webp";
  if (normalized.includes("heic")) return "heic";
  if (normalized.includes("quicktime")) return "mov";
  if (normalized.includes("webm")) return "webm";
  return kind === "video" ? "mp4" : "jpg";
}

function timestampMillis(value) {
  return value instanceof Timestamp ? value.toMillis() : 0;
}

async function canViewStory({db, story, viewerId}) {
  const ownerId = String(story.ownerId || "");
  if (!ownerId || !viewerId) return false;
  if (ownerId === viewerId) return true;
  if (story.audience === "everyone") return true;
  if (story.audience !== "close_friends") return false;
  const closeFriend = await db
    .collection("users")
    .doc(ownerId)
    .collection("close_friends")
    .doc(viewerId)
    .get();
  return closeFriend.exists;
}

async function signedStory({bucket, doc}) {
  const data = doc.data() || {};
  const storagePath = String(data.storagePath || "");
  if (!storagePath) return null;
  try {
    const [mediaUrl] = await bucket.file(storagePath).getSignedUrl({
      action: "read",
      expires: Date.now() + SIGNED_URL_LIFETIME_MS,
    });
    return {
      id: doc.id,
      ownerId: String(data.ownerId || ""),
      ownerName: String(data.ownerName || "WorldVoice"),
      ownerPhotoUrl: String(data.ownerPhotoUrl || ""),
      kind: String(data.kind || "image"),
      audience: String(data.audience || "everyone"),
      durationMs: Number(data.durationMs || 0),
      createdAtMs: timestampMillis(data.createdAt),
      expiresAtMs: timestampMillis(data.expiresAt),
      mediaUrl,
    };
  } catch (error) {
    console.error("Story signed URL failed:", doc.id, error?.message || error);
    return null;
  }
}

export function registerStoryRoutes({
  app,
  authenticatedUser,
  db,
  projectId,
}) {
  const bucketName = (
    process.env.FIREBASE_STORAGE_BUCKET ||
    (projectId ? `${projectId}.firebasestorage.app` : "")
  ).trim();
  const bucket = bucketName ? getStorage().bucket(bucketName) : null;

  app.post(
    "/stories/upload",
    express.raw({type: () => true, limit: "80mb"}),
    async (req, res, next) => {
      try {
        const user = await authenticatedUser(req);
        if (!bucket) fail("Story media storage is not configured.", 503);

        const kind = storyKind(String(req.headers["x-story-kind"] || ""));
        const audience = storyAudience(
          String(req.headers["x-story-audience"] || ""),
        );
        if (!kind || !audience) fail("Invalid story type or audience.");

        const contentType = String(req.headers["content-type"] || "")
          .split(";")[0]
          .trim()
          .toLowerCase();
        if (
          (kind === "image" && !contentType.startsWith("image/")) ||
          (kind === "video" && !contentType.startsWith("video/"))
        ) {
          fail("Story media type does not match the uploaded file.");
        }

        const payload = Buffer.isBuffer(req.body) ? req.body : Buffer.alloc(0);
        if (!payload.length) fail("Story media is empty.");
        const limit = kind === "video" ? MAX_VIDEO_BYTES : MAX_IMAGE_BYTES;
        if (payload.length > limit) {
          fail(kind === "video"
            ? "Story video is too large."
            : "Story image is too large.", 413);
        }

        const durationMs = Number(req.headers["x-story-duration-ms"] || 0);
        if (
          kind === "video" &&
          (!Number.isFinite(durationMs) ||
            durationMs <= 0 ||
            durationMs > MAX_VIDEO_MS)
        ) {
          fail("Story video must be 90 seconds or shorter.");
        }

        const profileRef = db.collection("users").doc(user.uid);
        const profileSnap = await profileRef.get();
        if (!profileSnap.exists) fail("WorldVoice profile is required.", 409);
        const profile = profileSnap.data() || {};
        if (audience === "close_friends" && profile.isVip !== true) {
          fail("Close Friends stories are a VIP feature.", 403);
        }

        const id = randomUUID().replaceAll("-", "");
        const ext = extensionFor(contentType, kind);
        const storagePath = `stories/${user.uid}/${id}.${ext}`;
        const now = Date.now();
        const expiresAt = Timestamp.fromMillis(now + STORY_LIFETIME_MS);

        await bucket.file(storagePath).save(payload, {
          resumable: false,
          contentType,
          metadata: {
            cacheControl: "private,max-age=900",
            metadata: {
              ownerId: user.uid,
              storyId: id,
            },
          },
        });

        const storyRef = db.collection("stories").doc(id);
        await storyRef.set({
          ownerId: user.uid,
          ownerName: String(
            profile.displayName || user.name || "WorldVoice",
          ).slice(0, 100),
          ownerPhotoUrl: String(profile.photoUrl || user.picture || ""),
          kind,
          audience,
          durationMs: kind === "video" ? Math.round(durationMs) : 7000,
          storagePath,
          createdAt: Timestamp.fromMillis(now),
          expiresAt,
        });

        return res.json({
          ok: true,
          storyId: id,
          expiresAtMs: expiresAt.toMillis(),
        });
      } catch (error) {
        next(error);
      }
    },
  );

  app.get("/stories/feed", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      if (!bucket) fail("Story media storage is not configured.", 503);

      const snapshot = await db
        .collection("stories")
        .where("expiresAt", ">", Timestamp.now())
        .limit(MAX_FEED_STORIES)
        .get();

      const active = snapshot.docs.filter(doc => {
        const data = doc.data() || {};
        return timestampMillis(data.expiresAt) > Date.now();
      });

      const closeOwners = [
        ...new Set(
          active
            .map(doc => doc.data() || {})
            .filter(data =>
              data.audience === "close_friends" &&
              data.ownerId !== user.uid)
            .map(data => String(data.ownerId || ""))
            .filter(Boolean),
        ),
      ];

      const closeAccess = new Map();
      await Promise.all(
        closeOwners.map(async ownerId => {
          const member = await db
            .collection("users")
            .doc(ownerId)
            .collection("close_friends")
            .doc(user.uid)
            .get();
          closeAccess.set(ownerId, member.exists);
        }),
      );

      const visible = active.filter(doc => {
        const data = doc.data() || {};
        const ownerId = String(data.ownerId || "");
        if (ownerId === user.uid) return true;
        if (data.audience === "everyone") return true;
        return data.audience === "close_friends" &&
          closeAccess.get(ownerId) === true;
      });

      visible.sort((a, b) =>
        timestampMillis(b.data()?.createdAt) -
        timestampMillis(a.data()?.createdAt));

      const stories = (
        await Promise.all(visible.map(doc => signedStory({bucket, doc})))
      ).filter(Boolean);

      return res.json({ok: true, stories});
    } catch (error) {
      next(error);
    }
  });

  app.post("/stories/view", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const storyId = String(req.body?.storyId || "").trim();
      if (!/^[a-f0-9]{32}$/.test(storyId)) fail("Invalid story.");

      const storyRef = db.collection("stories").doc(storyId);
      const storySnap = await storyRef.get();
      if (!storySnap.exists) fail("Story not found.", 404);
      const story = storySnap.data() || {};
      if (timestampMillis(story.expiresAt) <= Date.now()) {
        fail("Story expired.", 410);
      }
      if (!(await canViewStory({db, story, viewerId: user.uid}))) {
        fail("Story is not available to this viewer.", 403);
      }

      if (String(story.ownerId || "") !== user.uid) {
        const viewerProfile = await db.collection("users").doc(user.uid).get();
        const viewer = viewerProfile.data() || {};
        await storyRef.collection("views").doc(user.uid).set({
          uid: user.uid,
          displayName: String(
            viewer.displayName || user.name || "WorldVoice",
          ).slice(0, 100),
          photoUrl: String(viewer.photoUrl || user.picture || ""),
          viewedAt: Timestamp.now(),
        }, {merge: true});
      }

      return res.json({ok: true});
    } catch (error) {
      next(error);
    }
  });

  app.delete("/stories/:storyId", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const storyId = String(req.params.storyId || "").trim();
      if (!/^[a-f0-9]{32}$/.test(storyId)) fail("Invalid story.");

      const storyRef = db.collection("stories").doc(storyId);
      const storySnap = await storyRef.get();
      if (!storySnap.exists) return res.json({ok: true});
      const story = storySnap.data() || {};
      if (String(story.ownerId || "") !== user.uid) {
        fail("Only the story owner can delete it.", 403);
      }

      const storagePath = String(story.storagePath || "");
      if (bucket && storagePath) {
        await bucket.file(storagePath).delete({ignoreNotFound: true});
      }
      await storyRef.delete();
      return res.json({ok: true});
    } catch (error) {
      next(error);
    }
  });

  app.get("/stories/close-friends", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const profile = await db.collection("users").doc(user.uid).get();
      const isVip = profile.data()?.isVip === true;
      const selected = await db
        .collection("users")
        .doc(user.uid)
        .collection("close_friends")
        .get();
      return res.json({
        ok: true,
        isVip,
        userIds: selected.docs.map(doc => doc.id),
      });
    } catch (error) {
      next(error);
    }
  });

  app.get("/stories/close-friend-candidates", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const profile = await db.collection("users").doc(user.uid).get();
      if (profile.data()?.isVip !== true) {
        return res.json({ok: true, isVip: false, people: []});
      }

      const following = await db
        .collection("users")
        .doc(user.uid)
        .collection("following")
        .limit(MAX_CLOSE_FRIENDS)
        .get();
      const ids = following.docs.map(doc => doc.id);
      const refs = ids.map(id => db.collection("users").doc(id));
      const profiles = refs.length ? await db.getAll(...refs) : [];

      const people = profiles
        .filter(snap => snap.exists)
        .map(snap => {
          const data = snap.data() || {};
          return {
            uid: snap.id,
            displayName: String(
              data.displayName || data.name || "WorldVoice",
            ),
            photoUrl: String(data.photoUrl || ""),
            username: String(data.username || ""),
          };
        });

      return res.json({ok: true, isVip: true, people});
    } catch (error) {
      next(error);
    }
  });

  app.post("/stories/close-friends", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const profile = await db.collection("users").doc(user.uid).get();
      if (profile.data()?.isVip !== true) {
        fail("Close Friends is a VIP feature.", 403);
      }

      const rawIds = Array.isArray(req.body?.userIds) ? req.body.userIds : [];
      const ids = [...new Set(
        rawIds
          .map(value => String(value || "").trim())
          .filter(value => value && value !== user.uid),
      )];
      if (ids.length > MAX_CLOSE_FRIENDS) {
        fail("Close Friends list is too large.");
      }

      const followingRefs = ids.map(id =>
        db.collection("users").doc(user.uid).collection("following").doc(id));
      const follows = followingRefs.length
        ? await db.getAll(...followingRefs)
        : [];
      if (follows.some(snap => !snap.exists)) {
        fail("Close Friends can only contain people you follow.", 409);
      }

      const closeRef = db
        .collection("users")
        .doc(user.uid)
        .collection("close_friends");
      const old = await closeRef.get();
      const batch = db.batch();
      for (const doc of old.docs) batch.delete(doc.ref);
      for (const id of ids) {
        batch.set(closeRef.doc(id), {
          uid: id,
          addedAt: Timestamp.now(),
        });
      }
      await batch.commit();

      return res.json({ok: true, userIds: ids});
    } catch (error) {
      next(error);
    }
  });
}
