import {FieldValue} from "firebase-admin/firestore";
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
      // A repeat request cannot generate a second round of notifications.
      try {
        await eventRef.create({
          kind, sessionId, hostId: user.uid,
          createdAt: FieldValue.serverTimestamp(),
        });
      } catch (error) {
        if (error?.code === 6 || error?.code === "already-exists") {
          return res.json({ok: true, alreadyPublished: true});
        }
        throw error;
      }
      const activity = {
        kind, sessionId, hostId: user.uid,
        hostName: safeString(data.hostName, 80) || "WorldVoice",
        hostPhotoUrl: safeString(data.hostPhotoUrl, 1024),
        title: safeString(data.name || data.topic, 150) || "WorldVoice",
        languageCode: safeString(data.languageCode, 8) || "en",
        createdAt: FieldValue.serverTimestamp(),
      };
      let count = 0;
      // Beta limit: cap processing to prevent unbounded Render HTTP work.
      // Large audiences should move to a durable queued fan-out worker.
      const followers = await db.collection("users").doc(user.uid)
        .collection("followers").limit(500).get();
      const pushJobs = [];
      for (let start = 0; start < followers.docs.length; start += 150) {
        const group = followers.docs.slice(start, start + 150);
        const profiles = await Promise.all(group.map(doc =>
          db.collection("users").doc(doc.id).get()));
        const batch = db.batch();
        for (let i = 0; i < group.length; i++) {
          const uid = group[i].id;
          const profile = profiles[i].data() || {};
          if (uid === user.uid || profile.activityNotificationsEnabled === false ||
              (kind === "room" && profile.roomNotificationsEnabled === false) ||
              (kind === "live" && profile.liveNotificationsEnabled === false) ||
              (data.vipOnly === true && profile.isVip !== true &&
               profile.isAdmin !== true)) continue;
          batch.set(db.collection("users").doc(uid)
            .collection("activity_inbox").doc(eventId), activity);
          count++;
          const locale = safeString(profile.notificationLanguageCode, 8);
          pushJobs.push({uid, language: locale});
        }
        await batch.commit();
      }
      // The chat cards are the source of truth; push delivery is best-effort.
      await Promise.allSettled(pushJobs.map(x =>
        sendPush(db, x.uid, activity, x.language)));
      return res.json({ok: true, delivered: count,
        capped: followers.size >= 500});
    } catch (error) { next(error); }
  });
}
