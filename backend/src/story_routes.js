import {randomUUID} from "node:crypto";

import express from "express";
import {Timestamp} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";
import {v2 as cloudinary} from "cloudinary";

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

async function signedStory({bucketForLegacy, doc}) {
  const data = doc.data() || {};
  const publicId = String(data.cloudinaryPublicId || "");
  const storagePath = String(data.storagePath || "");
  if (!publicId && !storagePath) return null;
  try {
    let mediaUrl = "";
    if (publicId) {
      if (data.audience === "close_friends") {
        // A normal authenticated URL signature never expires. Instead issue a
        // 15-minute private-download link *only* to authorized story viewers.
        // Cloudinary does not CDN-cache this URL (higher free-plan bandwidth).
        mediaUrl = cloudinary.utils.private_download_url(
          publicId,
          String(data.cloudinaryFormat || "jpg"),
          {
            resource_type: data.kind === "video" ? "video" : "image",
            type: "authenticated",
            attachment: false,
            expires_at: Math.floor(Date.now() / 1000) + 15 * 60,
          },
        );
      } else {
        mediaUrl = String(data.cloudinarySecureUrl || "");
      }
    } else {
      const bucket = await bucketForLegacy(data);
      const [signedUrl] = await bucket.file(storagePath).getSignedUrl({
        action: "read",
        expires: Date.now() + SIGNED_URL_LIFETIME_MS,
      });
      mediaUrl = signedUrl;
    }
    if (!mediaUrl) return null;
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
  // Credentials live exclusively in Render environment variables, never
  // in Flutter, the Firestore story document, or source control.
  const cloudinaryConfigured = (() => {
    try {
      const uri = String(process.env.CLOUDINARY_URL || "").trim();
      if (uri) {
        const parsed = new URL(uri);
        if (parsed.protocol !== "cloudinary:" || !parsed.hostname ||
            !parsed.username || !parsed.password) return false;
        cloudinary.config({
          cloud_name: parsed.hostname,
          api_key: decodeURIComponent(parsed.username),
          api_secret: decodeURIComponent(parsed.password),
          secure: true,
        });
      } else {
        cloudinary.config({
          cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
          api_key: process.env.CLOUDINARY_API_KEY,
          api_secret: process.env.CLOUDINARY_API_SECRET,
          secure: true,
        });
      }
      const cfg = cloudinary.config();
      return Boolean(cfg.cloud_name && cfg.api_key && cfg.api_secret);
    } catch {
      return false;
    }
  })();

  async function uploadCloudinaryStory({payload, kind, audience, uid, id}) {
    const publicId = `worldvoice/stories/${uid}/${id}`;
    return await new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        {
          resource_type: kind,
          public_id: publicId,
          type: audience === "close_friends" ? "authenticated" : "upload",
          overwrite: false,
          unique_filename: false,
          timeout: 120000,
        },
        (error, result) => {
          if (error || !result) return reject(error || new Error("Upload failed."));
          resolve(result);
        },
      );
      stream.on("error", reject);
      stream.end(payload);
    });
  }

  // A Firebase project can use either the newer .firebasestorage.app bucket
  // or a legacy .appspot.com bucket. Do not assume one has been provisioned:
  // a nonexistent bucket currently causes a slow, opaque 404 after uploading.
  const bucketNames = [...new Set([
    process.env.FIREBASE_STORAGE_BUCKET?.trim(),
    projectId ? `${projectId}.firebasestorage.app` : "",
    projectId ? `${projectId}.appspot.com` : "",
  ].filter(Boolean))];
  let activeBucket = null;
  let bucketCheckedUntil = 0;
  let bucketCheckPromise = null;

  async function requireStoryBucket() {
    if (activeBucket && Date.now() < bucketCheckedUntil) {
      return activeBucket;
    }
    if (bucketCheckPromise) return bucketCheckPromise;
    bucketCheckPromise = (async () => {
      for (const name of bucketNames) {
        try {
          const candidate = getStorage().bucket(name);
          const [exists] = await candidate.exists();
          if (exists) {
            activeBucket = candidate;
            bucketCheckedUntil = Date.now() + 180000;
            return candidate;
          }
        } catch (error) {
          console.warn("Story storage bucket check failed:", error?.code || error?.message);
        }
      }
      activeBucket = null;
      const unavailable = new Error(
        "Story media storage is not ready. Configure Cloudinary on Render, " +
        "or create a Firebase Storage bucket, then retry."
      );
      unavailable.status = 503;
      unavailable.code = "STORY_STORAGE_NOT_READY";
      throw unavailable;
    })();
    try {
      return await bucketCheckPromise;
    } finally {
      bucketCheckPromise = null;
    }
  }

  // Opportunistic cleanup avoids accumulating 24-hour Story media on the
  // free Cloudinary plan. It runs on feed requests, no paid cron required.
  let cleanupInProgress = false;
  let lastCleanupAt = 0;
  async function cleanupExpiredStories() {
    if (cleanupInProgress || Date.now() - lastCleanupAt < 15 * 60 * 1000) {
      return;
    }
    lastCleanupAt = Date.now();
    cleanupInProgress = true;
    try {
      const expired = await db.collection("stories")
        .where("expiresAt", "<=", Timestamp.now()).limit(20).get();
      for (const doc of expired.docs) {
        const data = doc.data() || {};
        try {
          const publicId = String(data.cloudinaryPublicId || "");
          const storagePath = String(data.storagePath || "");
          if (publicId) {
            if (!cloudinaryConfigured ||
                !publicId.startsWith("worldvoice/stories/")) continue;
            await cloudinary.uploader.destroy(publicId, {
              resource_type: data.kind === "video" ? "video" : "image",
              type: data.audience === "close_friends"
                ? "authenticated" : "upload",
              invalidate: true,
            });
          } else if (storagePath) {
            const bucket = data.storageBucket
              ? getStorage().bucket(String(data.storageBucket))
              : await requireStoryBucket();
            await bucket.file(storagePath).delete({ignoreNotFound: true});
          }
          await doc.ref.delete();
        } catch (error) {
          console.warn("Expired story cleanup postponed:", doc.id,
            error?.code || error?.message);
        }
      }
    } catch (error) {
      console.warn("Expired story cleanup failed:", error?.code || error?.message);
    } finally {
      cleanupInProgress = false;
    }
  }

  // Check readiness BEFORE the client streams a potentially large video.
  // Cloudinary is preferred when present; legacy Firebase stories stay readable.
  app.get("/stories/storage-status", async (req, res, next) => {
    try {
      await authenticatedUser(req);
      if (cloudinaryConfigured) {
        return res.json({ok: true, ready: true, provider: "cloudinary"});
      }
      await requireStoryBucket();
      return res.json({ok: true, ready: true, provider: "firebase"});
    } catch (error) {
      next(error);
    }
  });

  app.post(
    "/stories/upload",
    express.raw({type: () => true, limit: "80mb"}),
    async (req, res, next) => {
      try {
        const user = await authenticatedUser(req);
        // Validate the provider before processing the request body.
        const bucket = cloudinaryConfigured ? null : await requireStoryBucket();

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

        let uploaded = null;
        if (cloudinaryConfigured) {
          uploaded = await uploadCloudinaryStory({
            payload, kind, audience, uid: user.uid, id,
          });
        } else {
          await bucket.file(storagePath).save(payload, {
            resumable: false,
            contentType,
            metadata: {
              cacheControl: "private,max-age=900",
              metadata: {ownerId: user.uid, storyId: id},
            },
          });
        }

        const storyRef = db.collection("stories").doc(id);
        try {
          await storyRef.set({
            ownerId: user.uid,
            ownerName: String(
              profile.displayName || user.name || "WorldVoice",
            ).slice(0, 100),
            ownerPhotoUrl: String(profile.photoUrl || user.picture || ""),
            kind,
            audience,
            durationMs: kind === "video" ? Math.round(durationMs) : 7000,
            ...(uploaded ? {
              cloudinaryPublicId: String(uploaded.public_id),
              cloudinaryFormat: String(uploaded.format || ext),
              cloudinarySecureUrl: audience === "everyone"
                ? String(uploaded.secure_url || "") : "",
            } : {
              storagePath,
              storageBucket: bucket.name,
            }),
            createdAt: Timestamp.fromMillis(now),
            expiresAt,
          });
        } catch (error) {
          // Avoid consuming free storage if saving the Firestore post fails.
          if (uploaded) {
            await cloudinary.uploader.destroy(uploaded.public_id, {
              resource_type: kind,
              type: audience === "close_friends" ? "authenticated" : "upload",
            }).catch(() => {});
          }
          throw error;
        }

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
        await Promise.all(visible.map(doc =>
          signedStory({
            bucketForLegacy: async data => data.storageBucket
              ? getStorage().bucket(String(data.storageBucket))
              : await requireStoryBucket(),
            doc,
          })
        ))
      ).filter(Boolean);

      // Return the feed immediately; cleanup never blocks story viewing.
      void cleanupExpiredStories();
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

      const publicId = String(story.cloudinaryPublicId || "");
      if (publicId) {
        await cloudinary.uploader.destroy(publicId, {
          resource_type: story.kind === "video" ? "video" : "image",
          type: story.audience === "close_friends" ? "authenticated" : "upload",
          invalidate: true,
        });
      } else {
        const storagePath = String(story.storagePath || "");
        if (storagePath) {
          const bucket = story.storageBucket
            ? getStorage().bucket(String(story.storageBucket))
            : await requireStoryBucket();
          await bucket.file(storagePath).delete({ignoreNotFound: true});
        }
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
