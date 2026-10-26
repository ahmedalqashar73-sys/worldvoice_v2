import {FieldValue} from "firebase-admin/firestore";

const MAX_POST_TEXT = 3000;
const MAX_COMMENT_TEXT = 800;
const MAX_FEED = 50;

const fail = (message, status = 400) => {
  throw Object.assign(new Error(message), {status});
};

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

function mediaType(value) {
  return value === "image" || value === "video" ? value : "";
}

function profileName(user, data) {
  return String(
    data?.displayName || data?.name || user.name || "WorldVoice",
  ).slice(0, 100);
}

function safeTimestampMs(value) {
  return value?.toMillis?.() || 0;
}

export function registerSocialRoutes({app, db, authenticatedUser}) {
  app.post("/social/posts", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const text = String(req.body?.text || "").trim();
      const type = mediaType(String(req.body?.mediaType || ""));
      const mediaUrl = String(req.body?.mediaUrl || "").trim();
      const mediaPublicId = String(req.body?.mediaPublicId || "").trim();

      if (text.length > MAX_POST_TEXT) {
        fail("Post text is too long.");
      }
      if (!text && !type) {
        fail("Add text, a photo, or a video.");
      }
      if (type && !validCloudinaryMedia(mediaUrl)) {
        fail("Invalid post media.");
      }
      if (!type && (mediaUrl || mediaPublicId)) {
        fail("Media metadata is invalid.");
      }

      const profileSnap = await db.collection("users").doc(user.uid).get();
      if (!profileSnap.exists) fail("WorldVoice profile is required.", 409);
      const profile = profileSnap.data() || {};

      const postRef = db.collection("posts").doc();
      await postRef.set({
        authorId: user.uid,
        authorName: profileName(user, profile),
        authorPhotoUrl: String(profile.photoUrl || user.picture || ""),
        text,
        mediaType: type || null,
        mediaUrl: type ? mediaUrl : null,
        mediaPublicId: type ? mediaPublicId : null,
        likeCount: 0,
        commentCount: 0,
        shareCount: 0,
        active: true,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      res.json({ok: true, postId: postRef.id});
    } catch (error) {
      next(error);
    }
  });

  app.get("/social/feed", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const requested = Number(req.query?.limit || 30);
      const limit = Number.isFinite(requested)
        ? Math.max(1, Math.min(MAX_FEED, Math.trunc(requested)))
        : 30;

      const snapshot = await db
        .collection("posts")
        .orderBy("createdAt", "desc")
        .limit(limit)
        .get();

      const visible = snapshot.docs.filter(doc => doc.data()?.active === true);
      const likedDocs = await Promise.all(
        visible.map(doc =>
          doc.ref.collection("likes").doc(user.uid).get()),
      );

      const posts = visible.map((doc, index) => {
        const data = doc.data() || {};
        return {
          id: doc.id,
          authorId: String(data.authorId || ""),
          authorName: String(data.authorName || "WorldVoice"),
          authorPhotoUrl: String(data.authorPhotoUrl || ""),
          text: String(data.text || ""),
          mediaType: String(data.mediaType || ""),
          mediaUrl: String(data.mediaUrl || ""),
          likeCount: Number(data.likeCount || 0),
          commentCount: Number(data.commentCount || 0),
          shareCount: Number(data.shareCount || 0),
          likedByMe: likedDocs[index]?.exists === true,
          createdAtMs: safeTimestampMs(data.createdAt),
        };
      });

      res.json({ok: true, posts});
    } catch (error) {
      next(error);
    }
  });

  app.post("/social/posts/:postId/like", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const postId = String(req.params.postId || "").trim();
      if (!postId || postId.length > 160) fail("Invalid post.");

      const postRef = db.collection("posts").doc(postId);
      const likeRef = postRef.collection("likes").doc(user.uid);

      const result = await db.runTransaction(async tx => {
        const [postSnap, likeSnap] = await Promise.all([
          tx.get(postRef),
          tx.get(likeRef),
        ]);
        if (!postSnap.exists || postSnap.data()?.active !== true) {
          fail("Post not found.", 404);
        }

        const current = Number(postSnap.data()?.likeCount || 0);
        if (likeSnap.exists) {
          tx.delete(likeRef);
          tx.update(postRef, {
            likeCount: Math.max(0, current - 1),
            updatedAt: FieldValue.serverTimestamp(),
          });
          return {liked: false, likeCount: Math.max(0, current - 1)};
        }

        tx.set(likeRef, {
          userId: user.uid,
          createdAt: FieldValue.serverTimestamp(),
        });
        tx.update(postRef, {
          likeCount: current + 1,
          updatedAt: FieldValue.serverTimestamp(),
        });
        return {liked: true, likeCount: current + 1};
      });

      res.json({ok: true, ...result});
    } catch (error) {
      next(error);
    }
  });

  app.get("/social/posts/:postId/comments", async (req, res, next) => {
    try {
      await authenticatedUser(req);
      const postId = String(req.params.postId || "").trim();
      if (!postId || postId.length > 160) fail("Invalid post.");

      const postRef = db.collection("posts").doc(postId);
      const postSnap = await postRef.get();
      if (!postSnap.exists || postSnap.data()?.active !== true) {
        fail("Post not found.", 404);
      }

      const commentsSnap = await postRef
        .collection("comments")
        .orderBy("createdAt", "asc")
        .limit(200)
        .get();

      const comments = commentsSnap.docs.map(doc => {
        const data = doc.data() || {};
        return {
          id: doc.id,
          authorId: String(data.authorId || ""),
          authorName: String(data.authorName || "WorldVoice"),
          authorPhotoUrl: String(data.authorPhotoUrl || ""),
          text: String(data.text || ""),
          createdAtMs: safeTimestampMs(data.createdAt),
        };
      });

      res.json({ok: true, comments});
    } catch (error) {
      next(error);
    }
  });

  app.post("/social/posts/:postId/comments", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const postId = String(req.params.postId || "").trim();
      const text = String(req.body?.text || "").trim();
      if (!postId || postId.length > 160) fail("Invalid post.");
      if (!text || text.length > MAX_COMMENT_TEXT) {
        fail("Comment must be between 1 and 800 characters.");
      }

      const postRef = db.collection("posts").doc(postId);
      const profileRef = db.collection("users").doc(user.uid);
      const commentRef = postRef.collection("comments").doc();

      await db.runTransaction(async tx => {
        const [postSnap, profileSnap] = await Promise.all([
          tx.get(postRef),
          tx.get(profileRef),
        ]);
        if (!postSnap.exists || postSnap.data()?.active !== true) {
          fail("Post not found.", 404);
        }
        if (!profileSnap.exists) fail("WorldVoice profile is required.", 409);

        const profile = profileSnap.data() || {};
        tx.create(commentRef, {
          authorId: user.uid,
          authorName: profileName(user, profile),
          authorPhotoUrl: String(profile.photoUrl || user.picture || ""),
          text,
          createdAt: FieldValue.serverTimestamp(),
        });
        tx.update(postRef, {
          commentCount: Number(postSnap.data()?.commentCount || 0) + 1,
          updatedAt: FieldValue.serverTimestamp(),
        });
      });

      res.json({ok: true, commentId: commentRef.id});
    } catch (error) {
      next(error);
    }
  });

  app.post("/social/posts/:postId/share", async (req, res, next) => {
    try {
      await authenticatedUser(req);
      const postId = String(req.params.postId || "").trim();
      if (!postId || postId.length > 160) fail("Invalid post.");

      const postRef = db.collection("posts").doc(postId);
      await db.runTransaction(async tx => {
        const postSnap = await tx.get(postRef);
        if (!postSnap.exists || postSnap.data()?.active !== true) {
          fail("Post not found.", 404);
        }
        tx.update(postRef, {
          shareCount: Number(postSnap.data()?.shareCount || 0) + 1,
          updatedAt: FieldValue.serverTimestamp(),
        });
      });

      res.json({ok: true});
    } catch (error) {
      next(error);
    }
  });

  app.delete("/social/posts/:postId", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const postId = String(req.params.postId || "").trim();
      if (!postId || postId.length > 160) fail("Invalid post.");

      const postRef = db.collection("posts").doc(postId);
      await db.runTransaction(async tx => {
        const postSnap = await tx.get(postRef);
        if (!postSnap.exists) return;
        if (String(postSnap.data()?.authorId || "") !== user.uid) {
          fail("Only the post owner can delete it.", 403);
        }
        tx.update(postRef, {
          active: false,
          deletedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      });

      res.json({ok: true});
    } catch (error) {
      next(error);
    }
  });
}
