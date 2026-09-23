# WorldVoice room backend

This service keeps privileged room credentials out of the Flutter APK.

## Endpoints

- `POST /agora/token` — verifies the Firebase ID token, verifies room membership/role, then issues an Agora RTC token.
- `POST /teacher-ai` — verifies Firebase identity and caption ownership, asks the configured OpenAI model for a concise language correction, and writes the result to Firestore.
- `GET /health` — health check.

## Required server environment

- `AGORA_APP_ID`
- `AGORA_APP_CERTIFICATE` — server only; never put this in Flutter or Git.
- `OPENAI_API_KEY` — server only.
- `OPENAI_TEACHER_MODEL` — the model you explicitly choose for Teacher AI.

The server uses Firebase Application Default Credentials. On Google Cloud Run, attach a service account with the Firebase permissions required for Auth verification and Firestore access. For local development, use `GOOGLE_APPLICATION_CREDENTIALS`.

## Flutter build configuration

After deploying this service, build WorldVoice with:

- `AGORA_TOKEN_ENDPOINT=https://YOUR_BACKEND/agora/token`
- `WORLDVOICE_TEACHER_AI_ENDPOINT=https://YOUR_BACKEND/teacher-ai`

Do not include the Agora App Certificate or OpenAI API key in Dart defines.

## Run locally

```bash
npm install
npm start
```

The backend requires Node.js 22 or later.
