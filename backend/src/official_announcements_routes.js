import {FieldValue} from "firebase-admin/firestore";
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

  app.post("/system/announcements/publish", async (req, res, next) => {
    try {
      const user = await authenticatedUser(req);
      await assertPublisher(db, user);
      const title = sourceText(req.body?.title, 150);
      const body = sourceText(req.body?.body, 3000);
      const lang = String(req.body?.sourceLanguage || "").trim();
      if (!SUPPORTED.includes(lang)) fail("Unsupported source language.");
      const translations = await translateAnnouncement(title, body, lang);
      const ref = db.collection("worldvoice_announcements").doc();
      await ref.set({
        authorId: user.uid,
        sourceLanguage: lang,
        translations,
        createdAt: FieldValue.serverTimestamp(),
        active: true,
        type: "official_announcement",
      });
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
