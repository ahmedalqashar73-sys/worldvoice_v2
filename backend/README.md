# WorldVoice room backend

This service keeps privileged room credentials out of the Flutter APK.

## Endpoints

- `POST /agora/token` — verifies the Firebase ID token, verifies room membership/role, then issues an Agora RTC token.
- `POST /teacher-ai` — verifies Firebase identity and caption ownership, asks the configured OpenAI model for a concise language correction, and writes the result to Firestore.
- `POST /teacher-ai/ask` — verifies room membership and answers direct language-learning questions from the in-room Teacher AI panel.
- `POST /store/purchase` — buys an owned room background using the server-authoritative coin balance.
- `POST /store/claim-reward` — claims the level-5 one-month room background reward.
- `POST /quiz/finish` — securely finalizes the quiz, stores the top three, and credits 5 coins once to first place.
- `POST /iap/verify` — verifies Google Play/App Store consumable purchases before crediting coins.
- `GET /health` — health check.

## Required server environment

- `AGORA_APP_ID`
- `AGORA_APP_CERTIFICATE` — server only; never put this in Flutter or Git.
- `OPENAI_API_KEY` — server only.
- `OPENAI_TEACHER_MODEL` — the model you explicitly choose for Teacher AI.

The server uses Firebase Application Default Credentials. On Google Cloud Run, attach a service account with the Firebase permissions required for Auth verification and Firestore access. For local development, use `GOOGLE_APPLICATION_CREDENTIALS`.

## Fixing `Invalid or expired Firebase authorization token`

The Flutter app is configured for Firebase project `worldvoice-37896`.
The server must verify tokens against **the same project**. Set
`FIREBASE_PROJECT_ID=worldvoice-37896` or `GOOGLE_CLOUD_PROJECT` before
starting Node. Prefer `GOOGLE_APPLICATION_CREDENTIALS` pointing at a
service-account JSON for that same Firebase project **outside the repository**.
The service account needs Firebase Authentication and Firestore permissions
to use `verifyIdToken(token, true)`, which checks revocation.

For local PowerShell testing (in the backend's PowerShell window):

```powershell
$env:FIREBASE_PROJECT_ID = "worldvoice-37896"
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\\secure\\worldvoice-service-account.json"
npm start
```

Replace the example JSON path with the actual private location. Never
upload or share this JSON or paste its contents into chat/GitHub. If the
server still rejects tokens, read the backend console's *error code*
(`auth/id-token-expired`, `auth/argument-error`,
`auth/insufficient-permission`, etc.) without sharing tokens or secrets.
The `GET /health` endpoint only tests reachability and does not validate
Firebase credentials. A signed-in user can sign out and back in to get
a fresh token before retrying.


## Flutter build configuration

After deploying this service, build WorldVoice with:

- `AGORA_TOKEN_ENDPOINT=https://YOUR_BACKEND/agora/token`
- Prefer one shared setting: `WORLDVOICE_ROOM_BACKEND_URL=https://YOUR_BACKEND`
- The older explicit `AGORA_TOKEN_ENDPOINT`, `WORLDVOICE_TEACHER_AI_ENDPOINT`, `WORLDVOICE_TEACHER_AI_ASK_ENDPOINT`, and `WORLDVOICE_STORE_ENDPOINT` values remain supported as overrides.

Do not include the Agora App Certificate or OpenAI API key in Dart defines.

## Run locally

```bash
npm install
npm start
```

The backend requires Node.js 22 or later.


## Google Play and App Store coin products

Create Firestore documents in `coin_products` with:

```text
active: true
coins: <integer>
androidProductId: <Google Play consumable product id>
iosProductId: <App Store consumable product id>
```

Prices are not stored or trusted by Flutter. The visible price comes from Google Play or the App Store.

For Android verification, the Cloud Run service account must have access to the Google Play Developer API for this app. The backend uses `ANDROID_PACKAGE_NAME` (default `com.worldvoice.worldvoice`) and Application Default Credentials.

For iOS verification, set `APPLE_IAP_KEY_ID`, `APPLE_IAP_ISSUER_ID`, and `APPLE_IAP_PRIVATE_KEY` from App Store Connect. Set `IOS_BUNDLE_ID` if it differs from `com.worldvoice.worldvoice`.

The backend deduplicates verified receipts in the server-only `iap_receipts` collection, so a store transaction cannot credit coins twice.
