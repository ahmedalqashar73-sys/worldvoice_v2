# WorldVoice Stories — dedicated Render backend

This optional dedicated service isolates Story media handling from Teacher AI,
Agora, the room economy, and Live. It reuses **the same Firebase project** for
Authentication, Firestore profiles, follows, Close Friends and story metadata.
Images and videos live in Cloudinary; they are not stored in Firestore.

## Deploy on Render

Create a new **Web Service** (not a new Render Environment, database, or GitHub project):

| Setting | Value |
| --- | --- |
| Name | `worldvoice-stories` (or an available unique name) |
| Repository | `ahmedalqashar73-sys/worldvoice_v2` |
| Branch | `feature/scalable-progress-foundation` (until merged to the original release branch) |
| Runtime | Node |
| Root directory | `backend` |
| Build command | `npm install` |
| Start command | `npm run start:stories` |
| Health path | `/health` |

**Environment variables (private inside Render):**

- `NODE_ENV=production`
- `FIREBASE_PROJECT_ID=worldvoice-37896` — the **existing** WorldVoice project, not a second database.
- `FIREBASE_SERVICE_ACCOUNT_JSON` — the existing project service account JSON,
  configured as a secret inside Render; alternatively mount a credentials secret
  file and point `GOOGLE_APPLICATION_CREDENTIALS` to its Render path.
- `CLOUDINARY_URL=cloudinary://API_KEY:API_SECRET@CLOUD_NAME` —
  use the actual value from the Cloudinary console in the **Render Environment**
  field, never in GitHub or Flutter. Treat it as a secret. URL-encode special
  characters in the credential components when needed.

Do **not** set `AGORA_APP_CERTIFICATE`, Groq, Stripe, or other unrelated secrets
for this isolated service.

After Render reports Live, check `https://<actual-stories-service-host>/health`
for `{"ok":true,"service":"worldvoice-stories"}`. This does not verify the
Cloudinary credentials. Next, test the authenticated `GET /stories/storage-status`
from the app; it should report `provider: cloudinary`. Finally, publish a
single small image and confirm it appears in the story feed.

## Connect Flutter

Pass the **actual Render-assigned URL** to Flutter; do not guess the name:

```text
--dart-define=WORLDVOICE_STORY_BACKEND_URL=https://ACTUAL-STORIES-HOST.onrender.com
```

Do not continue passing the old teacher-AI URL for
`WORLDVOICE_STORY_BACKEND_URL`. Other WorldVoice endpoints remain unchanged.

### Separation and maintenance

- This entrypoint registers **only** the Story routes, and `/health`.
- The original `backend/src/server.js` and its startup command are unchanged.
- The original users, follows, Close Friends and `stories` Firestore collections
  are reused; creating another database would disconnect the social graph.
- Story upload requires a Firebase ID token. Media stored for Close Friends
  uses restricted Cloudinary delivery, and must not be distributed as a public URL.
- Real story publishing still requires the Cloudinary account to have valid API
  credentials, and the Render service to have working Firebase Admin credentials.
