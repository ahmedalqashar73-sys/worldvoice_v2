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

## Permanent Android release / avoid 127.0.0.1

The Android debug-only URL `http://127.0.0.1:8080` relies on an **attached USB cable**,
the laptop's Node.js process and `adb reverse`. It is never appropriate for a
distributed APK. Firebase Authentication and Firestore do **not** host this Node.js
Agora token server automatically.

**One-time setup:** Cloud Run can host this backend continuously on an HTTPS URL
(with scale-to-zero when idle). It requires linking a billing account to the
Firebase project; linking billing normally changes Spark to Blaze. Free quota is
not a guarantee of zero charges. Review pricing/budget alerts before proceeding.
Do not deploy or enable billing without account owner approval.

1. In Google Cloud for project `worldvoice-37896`, enable Cloud Run,
   Cloud Build, Artifact Registry and Secret Manager APIs and link billing.
   Install/login to Google Cloud CLI. Ensure the deployer/Cloud Build identities
   have the documented source deployment roles.
2. In IAM, create a dedicated Cloud Run service account in the same project.
   Give it only the Firebase Auth and Firestore permissions needed to verify
   users and room memberships. In Secret Manager, create secret
   `worldvoice-agora-cert` containing the **rotated** Agora App Certificate
   (a previously shared certificate must not be re-used in production).
   Grant the service account `Secret Manager Secret Accessor` on that secret.
   Do not put the downloaded local Firebase JSON or Agora Certificate into
   Flutter, Git, command flags, or a public URL.
3. From the repository root on Windows, use
   `./scripts/deploy_cloud_run.ps1 -ServiceAccount 'YOUR_ACCOUNT@worldvoice-37896.iam.gserviceaccount.com'`.
   The script checks that the secret exists and deploys the source with an
   attached service identity, explicit Firebase project ID, and certificate
   injection. Cloud Run must be reachable from phones for token requests,
   so the service permits unauthenticated *HTTP access*; sensitive routes
   still verify Firebase ID tokens, role and room membership themselves.
   Review all endpoints and authorization before inviting a broad public audience.
4. Verify `https://YOUR-SERVICE-URL/health`, then test **a real signed-in
   room token request** from the app. A successful health probe does not
   prove Firebase/Agora authorization works. Close and reopen the room and
   app on a phone **without USB**, preferably using mobile data, and test
   screen share from a second phone.
5. From the green-room branch root run
   `./scripts/build_android_release.ps1 -BackendUrl 'https://YOUR-SERVICE-URL'`.
   This script refuses localhost/plain HTTP, analyzes code and builds
   `build/app/outputs/flutter-apk/app-release.apk`. Distribute only after
   multi-device release testing. The app build receives the public Agora App ID,
   never the server-only Certificate.

For local development only, continue using `npm install`, `npm start`,
`adb reverse tcp:8080 tcp:8080`, and Flutter `--dart-define` pointed to
`http://127.0.0.1:8080`. These settings do not persist when the Node
process stops or USB reverse is removed.

If you want a Firebase Hosting link for a website, Hosting can separately
route dynamic requests to Cloud Run, but it does not replace the Cloud Run
Node.js token service or publish an Android APK by itself.
