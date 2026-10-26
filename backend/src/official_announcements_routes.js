import {FieldValue, FieldPath} from "firebase-admin/firestore";
import {createHash} from "node:crypto";
import {getAuth} from "firebase-admin/auth";
import {getMessaging} from "firebase-admin/messaging";

const SUPPORTED = ["ar", "en", "es", "fr", "zh", "ko"];
const fail = (message, status = 400) =>
  Object.assign(new Error(message), {status});

function sourceText(value, limit) {
  const text = String(value || "").trim();
  if (!text || text.length > limit) fail("Announcement text length is invalid.");
  return text;
}

async function assertPublisher(db, user) {
  const doc = await db.collection("admins").doc(user.uid).get();
  const data = doc.data() || {};
  if (data.active !== true ||
      !(data.role === "super_admin" ||
       (Array.isArray(data.permissions) &&
        data.permissions.includes("send_announcements")))) {
    fail("Only an authorized WorldVoice administrator can publish.", 403);
  }
}

async function translateAnnouncement(title, body, sourceLanguage) {
  const key = String(process.env.GROQ_API_KEY || "").trim();
  if (!key) fail("GROQ_API_KEY is required for multilingual broadcasts.", 503);
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 25000);
  try {
    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      signal: controller.signal,
      headers: {
        Authorization: `Bearer ${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: process.env.GROQ_TEACHER_MODEL || "openai/gpt-oss-20b",
        messages: [
          {role: "system", content:
            "Translate the provided announcement into Arabic ar, English en, " +
            "Spanish es, French fr, Simplified Chinese zh and Korean ko. " +
            "Return ONLY valid JSON with exactly six keys ar,en,es,fr,zh,ko. " +
            "Each key maps to an object containing translated title and body. " +
            "Keep proper names such as WorldVoice unchanged. Do not add claims, " +
            "links or instructions not in the original announcement."},
          {role: "user", content: JSON.stringify({
            sourceLanguage, title, body,
          })},
        ],
        response_format: {type: "json_object"},
        max_completion_tokens: 1800,
        temperature: 0.1,
      }),
    });
    if (!response.ok) fail("Announcement translation provider unavailable.", 503);
    const json = await response.json();
    const raw = json.choices?.[0]?.message?.content;
    const translations = JSON.parse(String(raw || "{}"));
    const result = {};
    for (const language of SUPPORTED) {
      const item = translations[language];
      if (!item || typeof item.title !== "string" ||
          typeof item.body !== "string" ||
          !item.title.trim() || !item.body.trim()) {
        fail("Incomplete announcement translations. Nothing was published.", 503);
      }
      result[language] = {
        title: item.title.trim().slice(0, 150),
        body: item.body.trim().slice(0, 3000),
      };
    }
    result[sourceLanguage] = {title, body};
    return result;
  } catch (error) {
    if (error.status) throw error;
    fail("Could not translate the announcement. Nothing was published.", 503);
  } finally {
    clearTimeout(timer);
  }
}

export function registerOfficialAnnouncementRoutes({app, db, authenticatedUser}) {
  app.post("/system/announcements/can-publish", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      let canPublish = true;
      try { await assertPublisher(db, user); } catch (_) { canPublish = false; }
      res.json({ok: true, canPublish,
        emailConfigured: Boolean(process.env.RESEND_API_KEY &&
          process.env.WORLDVOICE_FROM_EMAIL)});
    } catch (error) { next(error); }
  });

  // A member explicitly opts into or out of update emails. This field
  // is changed by trusted backend code, not editable Firestore client rules.
  app.post("/system/announcements/email/preference", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      const enabled = req.body?.enabled === true;
      await db.collection("users").doc(user.uid).set({
        emailAnnouncementsOptIn: enabled,
        emailAnnouncementsChangedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      res.json({ok: true, enabled});
    } catch (error) { next(error); }
  });

  // A resumable, low-cost beta email delivery batch. The admin app keeps
  // calling this while online and can resume if disconnected. Never email
  // members who did not explicitly opt in, and never expose addresses.
  app.post("/system/announcements/email/process", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      await assertPublisher(db, user);
      const announcementId = String(req.body?.announcementId || "");
      if (!/^[A-Za-z0-9]{15,40}$/.test(announcementId)) {
        fail("Invalid announcement identifier.");
      }
      const key = process.env.RESEND_API_KEY;
      const from = process.env.WORLDVOICE_FROM_EMAIL;
      if (!key || !from) fail("Email sender not configured.", 503);
      const ref = db.collection("worldvoice_announcements").doc(announcementId);
      const snapshot = await ref.get();
      const announcement = snapshot.data();
      if (!announcement || announcement.emailEnabled !== true) {
        fail("Announcement has no email delivery.", 404);
      }
      if (announcement.emailComplete === true) {
        return res.json({ok: true, complete: true,
          sent: announcement.emailSent || 0});
      }
      // Prevent two admins from sending the same batch concurrently.
      const lock = await db.runTransaction(async tx => {
        const latest = await tx.get(ref);
        const state = latest.data() || {};
        const lockedAt = state.emailProcessingAt?.toMillis?.() || 0;
        if (lockedAt > Date.now() - 90000) {
          fail("Email batch already in progress.", 409);
        }
        tx.update(ref, {emailProcessingAt: FieldValue.serverTimestamp()});
        return state;
      });
      try {
        let query = db.collection("users")
          .where("emailAnnouncementsOptIn", "==", true)
          .orderBy(FieldPath.documentId()).limit(30);
        if (lock.emailCursor) query = query.startAfter(lock.emailCursor);
        const recipients = await query.get();
        const docs = recipients.docs;
        if (docs.length === 0) {
          await ref.update({emailComplete: true,
            emailProcessingAt: FieldValue.delete()});
          return res.json({ok: true, complete: true,
            sent: lock.emailSent || 0});
        }
        const userInfo = await getAuth().getUsers(docs.map(doc => ({
          uid: doc.id,
        })));
        const verified = new Map(userInfo.users.filter(record =>
          record.emailVerified && record.email).map(record =>
          [record.uid, record.email]));
        const messages = [];
        for (const recipient of docs) {
          const email = verified.get(recipient.id);
          if (!email) continue;
          const requested = String(
            recipient.data()?.notificationLanguageCode || "en");
          const localized = announcement.translations?.[requested] ||
            announcement.translations?.en;
          if (!localized) continue;
          messages.push({
            from, to: [email],
            subject: String(localized.title).slice(0, 150),
            text: String(localized.body) +
              "\n\nWorldVoice — Manage email preferences in the app.",
          });
        }
        if (messages.length) {
          const response = await fetch("https://api.resend.com/emails/batch", {
            method: "POST",
            headers: {
              Authorization: `Bearer ${key}`,
              "Content-Type": "application/json",
              "Idempotency-Key": `worldvoice-${announcementId}-${docs[0].id}`,
            },
            body: JSON.stringify(messages),
            signal: AbortSignal.timeout(20000),
          });
          if (!response.ok) {
            fail("Email delivery provider rejected batch.", 503);
          }
        }
        const complete = docs.length < 30;
        await ref.update({
          emailCursor: docs[docs.length - 1].id,
          emailComplete: complete,
          emailSent: FieldValue.increment(messages.length),
          emailProcessingAt: FieldValue.delete(),
        });
        return res.json({ok: true, complete, batchSent: messages.length,
          sent: (lock.emailSent || 0) + messages.length});
      } finally {
        await ref.update({emailProcessingAt: FieldValue.delete()})
          .catch(() => {});
      }
    } catch (error) { next(error); }
  });

  app.post("/system/announcements/publish", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      await assertPublisher(db, user);
      const title = sourceText(req.body?.title, 150);
      const body = sourceText(req.body?.body, 3000);
      const lang = String(req.body?.sourceLanguage || "").trim();
      if (!SUPPORTED.includes(lang)) fail("Unsupported source language.");
      const requestId = String(req.body?.requestId || "").trim();
      if (!/^[A-Za-z0-9_-]{12,100}$/.test(requestId)) {
        fail("Invalid announcement idempotency key.");
      }
      const emailEnabled = req.body?.sendEmail === true;
      if (emailEnabled && !(process.env.RESEND_API_KEY &&
          process.env.WORLDVOICE_FROM_EMAIL)) {
        fail("Email sender is not configured on the server.", 503);
      }
      const docId = createHash("sha256").update(
        `worldvoice:announcement:${user.uid}:${requestId}`).digest("hex");
      const contentDigest = createHash("sha256").update(
        JSON.stringify({title, body, lang, emailEnabled})).digest("hex");
      const ref = db.collection("worldvoice_announcements").doc(docId);
      const existing = await ref.get();
      if (existing.exists) {
        if (existing.data()?.contentDigest !== contentDigest) {
          fail("This request ID was already used for another announcement.", 409);
        }
        return res.json({ok: true, announcementId: ref.id,
          alreadyPublished: true, emailConfigured: Boolean(
            process.env.RESEND_API_KEY && process.env.WORLDVOICE_FROM_EMAIL)});
      }
      const translations = await translateAnnouncement(title, body, lang);
      try {
        await ref.create({
        authorId: user.uid,
        contentDigest,
        sourceLanguage: lang,
        translations,
        createdAt: FieldValue.serverTimestamp(),
        active: true,
        type: "official_announcement",
        emailEnabled,
        emailComplete: !emailEnabled,
        emailCursor: null,
        emailSent: 0,
        });
      } catch (error) {
        if (error?.code === 6 || error?.code === "already-exists") {
          return res.json({ok: true, announcementId: ref.id,
            alreadyPublished: true});
        }
        throw error;
      }
      // Broadcast only public announcement text, never recipient metadata.
      // A Firebase device must opt into the topic independently.
      let pushSent = false;
      try {
        const pushResults = await getMessaging().sendEach(SUPPORTED.map(language => ({
          topic: `worldvoice_announcements_${language}`,
          notification: {
            title: "WorldVoice",
            body: translations[language].title,
          },
          data: {type: "worldvoice_announcement", announcementId: ref.id},
          android: {priority: "normal"},
        })));
        pushSent = pushResults.successCount === SUPPORTED.length;
      } catch (error) {
        console.warn("Official announcement FCM unavailable:", error?.code);
      }
      return res.json({ok: true, announcementId: ref.id, pushSent,
        emailConfigured: Boolean(process.env.RESEND_API_KEY &&
          process.env.WORLDVOICE_FROM_EMAIL)});
    } catch (error) { next(error); }
  });
}
