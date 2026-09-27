# WorldVoice: original GREEN room + fixed board + hosted Agora tokens

This release branch starts from `fix/green-room-board-only-20260927`.
**Do not merge the purple room branch**. The original room screen, stage
layout, mic and other room controls are preserved. The only behavioral
changes outside the board are token-server reliability and deployment.

## Why the room worked, then broke after restart

`127.0.0.1:8080` inside an Android APK is the PHONE's loopback address.
It reached the PC only while USB + `adb reverse` + local `npm start`
were running. Reopening a room requires another Agora RTC token, so the
next join failed after the laptop server or USB connection stopped.
This is not solved by reinstalling Agora or re-entering a temporary token.

The release build MUST point to a publicly reachable HTTPS backend.
The server runs independently in Cloud Run and creates a fresh,
short-lived Agora RTC token for each authenticated room join/renewal.

## Step 1: Google Cloud/Firebase prerequisites (user action)

1. Open Firebase project `worldvoice-37896`, verify you are its owner.
2. Cloud Run requires Google Cloud billing: link a billing account, which
   also switches Firebase Spark to Blaze. Cloud Run, Cloud Build,
   Artifact Registry, logs, and Secret Manager can incur charges. Review
   pricing and create budget alerts BEFORE proceeding; never assume free.
3. In Agora Console, regenerate the **Primary Certificate** because the
   earlier certificate was shared. Create a new Google Cloud Secret
   Manager secret named **worldvoice-agora-certificate** under this
   Google project. Add the fresh 32-character certificate as its
   *first secret version*. Do NOT share the certificate or put it in
   Flutter, PowerShell history, GitHub, or Google Drive.
4. Install Google Cloud CLI on the deployment PC and sign in:
   `gcloud auth login`
   If `gcloud` is not found, install it or use Google Cloud Shell.
5. Cloud Run runtime uses an attached Google service account, so the
   downloaded Firebase private JSON stays only on the local PC.
   Never upload it to Cloud Run or the repository.

## Step 2: Deploy the HTTPS token server

In the **green release worktree**, run:

```powershell
cd C:\Users\AHMED\worldvoice_v2
git fetch origin
git worktree add --detach C:\Users\AHMED\worldvoice_green_release origin/release/green-room-remote-backend-20260927
cd C:\Users\AHMED\worldvoice_green_release
.\scripts\deploy-green-backend.ps1 -AgoraAppId YOUR_AGORA_APP_ID
```

The script asks for explicit confirmation before creating billable
resources. It attaches an identity with Firebase Auth read + Firestore
permissions, and reads the rotating certificate from Secret Manager.
It deploys the existing `backend/src/server.js`, without embedding keys.
The default Dammam region is `me-central2`, with min instances zero.
Cloud Run still has cold starts; the app has short bounded retries.
Read the generated HTTPS service URL after `/ready` succeeds.

`/ready` only checks configuration is present; finish an authenticated
two-device room join to prove Firebase permissions and Agora credentials
match. `/health` alone does not validate either of these.

## Step 3: Build the invite-only Android APK (never localhost)

```powershell
cd C:\Users\AHMED\worldvoice_green_release
.\scripts\build-green-tester.ps1 -BackendUrl "https://YOUR_CLOUD_RUN_URL" -AgoraAppId YOUR_AGORA_APP_ID
```

The script runs `flutter pub get`, `flutter analyze`, and then builds
an APK with `WORLDVOICE_ROOM_BACKEND_URL=https://...`.
The APK is in `build/app/outputs/flutter-apk/app-release.apk`.

Current `android/app/build.gradle.kts` still uses a DEBUG signing key
for release builds. This is for invite-only tests only. Configure real
release signing before any public Google Play release.

To distribute *after you verify the build* (Firebase CLI required):

```powershell
.\scripts\build-green-tester.ps1 -BackendUrl "https://YOUR_CLOUD_RUN_URL" -AgoraAppId YOUR_AGORA_APP_ID -UploadToFirebase -Testers "tester@example.com"
```

The Firebase app ID in the upload script is for Android package
`com.worldvoice.app`, NOT the separate Android Firebase registration
for `com.worldvoice.worldvoice`. Confirm the correct app selection on
the Firebase App Distribution page.

## Device acceptance test, BEFORE sharing with friends

- Install the APK on two phones and sign in as two different users.
- Start room on A, join on B, hear two-way audio and test host mute.
- Close and reopen the room on both phones **without** a USB cable,
  laptop PowerShell, or `adb reverse`. Verify a new Agora join succeeds.
- Enable screen sharing on A and confirm B sees the expanded board.
- Upload PDF and image, open them and reopen them to test local cache.
- Test when network temporarily drops and returns.
- Stop the local backend entirely, reopen the phones and repeat.
- Do not release to more testers if hosted token generation is failing.

## Offline local-only fallback before billing is configured

If Cloud Run billing is not enabled, nothing on Firebase Spark can
substitute for this persistent HTTPS server. For local debugging only,
save a **new rotated** Agora primary certificate encrypted to your
Windows profile and then restart locally using:

```powershell
.\scripts\start-local-green.ps1 -SaveCertificate
.\scripts\start-local-green.ps1
```

The second command can be reused without re-entering the secret on
that same PC/user account, but the API still stops when the laptop
stops. It is NOT an end-user distribution method.
