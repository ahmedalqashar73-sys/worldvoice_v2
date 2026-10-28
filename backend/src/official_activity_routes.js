import {FieldValue, FieldPath} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

const invalid = (message, status = 400) =>
  Object.assign(new Error(message), {status});
const langs = new Set(["ar", "en", "es", "fr", "zh", "ko"]);

const copy = {
  room: {
    ar: "بدأ شخص تتابعه غرفة صوتية جديدة",
    en: "Someone you follow started a voice room",
    es: "Alguien que sigues abrió una sala de voz",
    fr: "Une personne suivie a ouvert un salon vocal",
    zh: "你关注的人开启了语音房间",
    ko: "팔로우한 사용자가 음성방을 시작했어요",
  },
  live: {
    ar: "بدأ شخص تتابعه بثًا مباشرًا",
    en: "Someone you follow started a live stream",
    es: "Alguien que sigues inició un directo",
    fr: "Une personne suivie a lancé un direct",
    zh: "你关注的人开始直播了",
    ko: "팔로우한 사용자가 라이브를 시작했어요",
  },
};

const safeString = (v, n = 150) => String(v || "").trim().slice(0, n);
const activityId = (kind, sessionId) => `${kind}_${sessionId}`;

async function sendPush(db, uid, activity, language) {
  try {
    const tokens = await db.collection("users").doc(uid)
      .collection("notification_devices").limit(3).get();
    const localeFallback = langs.has(language) ? language : "en";
    for (const device of tokens.docs) {
      const token = safeString(device.data()?.token, 2048);
      if (!token) continue;
      const locale = langs.has(device.data()?.languageCode)
        ? device.data().languageCode : localeFallback;
      await getMessaging().send({
        token,
        notification: {
          title: "WorldVoice",
          body: `${copy[activity.kind][locale]} · ${activity.hostName}`,
        },
        data: {
          type: "worldvoice_activity",
          kind: activity.kind,
          sessionId: activity.sessionId,
        },
        android: {priority: "high"},
      }).catch(() => {});
    }
  } catch (error) {
    console.warn("Activity push unavailable:", error?.code || "unknown");
  }
}

export function registerOfficialActivityRoutes({app, db, authenticatedUser}) {
  app.post("/system/activity/preferences", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      if (typeof req.body?.rooms !== "boolean" ||
          typeof req.body?.lives !== "boolean") {
        throw invalid("Notification preferences must be booleans.");
      }
      await db.collection("users").doc(user.uid).set({
        roomNotificationsEnabled: req.body.rooms,
        liveNotificationsEnabled: req.body.lives,
        notificationPreferencesUpdatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      return res.json({ok: true});
    } catch (error) { next(error); }
  });

  // Persist only the caller's own device token. Tokens must never be accepted
  // for another account or exposed through Firestore rules.
  app.post("/system/notifications/device", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const token = safeString(req.body?.token, 2048);
      const locale = safeString(req.body?.languageCode, 8);
      if (token.length < 30 || token.length > 2048) {
        throw invalid("Invalid push token.");
      }
      const {createHash} = await import("node:crypto");
      const tokenId = createHash("sha256").update(token).digest("hex");
      const ownerRef = db.collection("notification_token_owners").doc(tokenId);
      const myDeviceRef = db.collection("users").doc(user.uid)
        .collection("notification_devices").doc(tokenId);
      await db.runTransaction(async tx => {
        const owner = await tx.get(ownerRef);
        const previousUid = owner.data()?.uid;
        if (previousUid && previousUid !== user.uid) {
          tx.delete(db.collection("users").doc(previousUid)
            .collection("notification_devices").doc(tokenId));
        }
        tx.set(ownerRef, {uid: user.uid,
          updatedAt: FieldValue.serverTimestamp()});
        tx.set(myDeviceRef, {
          token, languageCode: langs.has(locale) ? locale : "en",
          updatedAt: FieldValue.serverTimestamp(),
        });
      });
      await db.collection("users").doc(user.uid).set({
        notificationLanguageCode: langs.has(locale) ? locale : "en",
      }, {merge: true});
      res.json({ok: true});
    } catch (error) { next(error); }
  });

  // Publish only after a real, server-verifiable session is open.
  // Client-supplied titles, hosts and recipient lists are never trusted.
  app.post("/system/activity/publish", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const kind = safeString(req.body?.kind, 12);
      const sessionId = safeString(req.body?.sessionId, 150);
      if (!["room", "live"].includes(kind) ||
          !/^[A-Za-z0-9_-]{4,150}$/.test(sessionId)) {
        throw invalid("Invalid activity.");
      }
      const source = await db.collection(
        kind === "room" ? "rooms" : "live_sessions",
      ).doc(sessionId).get();
      if (!source.exists) throw invalid("Session not found.", 404);
      const data = source.data() || {};
      if (data.hostId !== user.uid) throw invalid("Host required.", 403);
      if (kind === "room" ?
        (data.isOpen !== true || data.isPrivate === true) :
        data.isLive !== true) {
        throw invalid("Only open public sessions can be shared.", 409);
      }
      const eventId = activityId(kind, sessionId);
      const eventRef = db.collection("worldvoice_activity_events").doc(eventId);
      // Process follower fan-out in resumable pages. The event is durable:
      // an interrupted request can resume without dropping later followers.
      const claim = await db.runTransaction(async tx => {
        const snap = await tx.get(eventRef);
        const state = snap.data() || {};
        if (state.deliveryComplete === true) {
          return {complete: true, delivered: state.delivered || 0};
        }
        const lockedAt = state.processingAt?.toMillis?.() || 0;
        if (lockedAt > Date.now() - 60000) {
          return {busy: true};
        }
        if (!snap.exists) {
          tx.create(eventRef, {
            kind, sessionId, hostId: user.uid,
            delivered: 0, deliveryCursor: null,
            deliveryComplete: false,
            createdAt: FieldValue.serverTimestamp(),
            processingAt: FieldValue.serverTimestamp(),
          });
        } else {
          tx.update(eventRef, {processingAt: FieldValue.serverTimestamp()});
        }
        return {cursor: state.deliveryCursor || null,
          delivered: state.delivered || 0};
      });
      if (claim.complete) {
        return res.json({ok: true, complete: true,
          delivered: claim.delivered, alreadyPublished: true});
      }
      if (claim.busy) {
        return res.status(409).json({ok: false,
          error: "Activity delivery already in progress; retry shortly."});
      }
      try {
        const activity = {
          kind, sessionId, hostId: user.uid,
          hostName: safeString(data.hostName, 80) || "WorldVoice",
          hostPhotoUrl: safeString(data.hostPhotoUrl, 1024),
          title: safeString(data.name || data.topic, 150) || "WorldVoice",
          languageCode: safeString(data.languageCode, 8) || "en",
          createdAt: FieldValue.serverTimestamp(),
        };
        const pageSize = 50;
        let followersQuery = db.collection("users").doc(user.uid)
          .collection("followers")
          .orderBy(FieldPath.documentId()).limit(pageSize);
        if (claim.cursor) {
          followersQuery = followersQuery.startAfter(claim.cursor);
        }
        const followers = await followersQuery.get();
        const profiles = await Promise.all(followers.docs.map(doc =>
          db.collection("users").doc(doc.id).get()));
        const batch = db.batch();
        const pushJobs = [];
        for (let i = 0; i < followers.docs.length; i++) {
          const uid = followers.docs[i].id;
          const profile = profiles[i].data() || {};
          if (uid === user.uid ||
              profile.activityNotificationsEnabled === false ||
              (kind === "room" && profile.roomNotificationsEnabled === false) ||
              (kind === "live" && profile.liveNotificationsEnabled === false) ||
              (data.vipOnly === true && profile.isVip !== true &&
               profile.isAdmin !== true)) continue;
          batch.set(db.collection("users").doc(uid)
            .collection("activity_inbox").doc(eventId), activity);
          const language = safeString(profile.notificationLanguageCode, 8);
          pushJobs.push({uid, language});
        }
        if (pushJobs.length) await batch.commit();
        await Promise.allSettled(pushJobs.map(x =>
          sendPush(db, x.uid, activity, x.language)));
        const complete = followers.docs.length < pageSize;
        const cursor = followers.docs.length
          ? followers.docs[followers.docs.length - 1].id
          : claim.cursor;
        const delivered = claim.delivered + pushJobs.length;
        await eventRef.update({
          deliveryCursor: cursor, delivered,
          deliveryComplete: complete,
          processingAt: FieldValue.delete(),
        });
        return res.json({ok: true, complete, delivered});
      } catch (error) {
        await eventRef.update({processingAt: FieldValue.delete()})
          .catch(() => {});
        throw error;
      }
    } catch (error) { next(error); }
  });
}
