# WorldVoice — local-first direct chat integration (2026-10-24)

## Status
Implemented in `feature/scalable-progress-foundation` as a **development integration**, not a verified production release. Do not publish or remove existing Cloudinary/Firestore transcripts before a migration audit and two-device QA.

## User-facing behavior
- Show **تم الإرسال** / Sent with no checkmarks after saving to the encrypted local outbox.
- No waiting indicator; successful recipient read acknowledgments show **تمت القراءة** / Read.
- Long-press text: copy, edit, delete on this phone, unsend for everyone.
- Six vector, retina-independent, calming wallpapers watermarked WorldVoice.
- Header menu: profile, wallpapers, block/unblock, report, delete local chat.
- Direct photos, videos, voice, PDF: local app-private files transferred in bounded chunks.
- Gifts and paid economy remain backend-authoritative. Calls keep existing Agora/backend path.

## Architecture
`LocalChatStore`: per-Firebase-UID, per-chat AES-256-GCM JSON transcript; key in device secure keystore; atomic-ish temporary file replacement. Media files reside inside application support sandbox. Local DB is not synchronized across devices.

`DirectChatTransport`: ordered, reliable WebRTC DataChannel carrying message edits, withdrawals, acknowledgments and chunked media. Firestore `chats/{chatId}/p2p_signals/{uid}` contains only temporary SDP/ICE metadata, never chat content, files or chat media URLs. Signal writes are limited to authenticated verified chat members by `firestore.rules`.

## Known limitations / required production work
1. **Both participants must currently open the direct conversation.** Current sessions are foreground route-scoped. Neither a closed Android app nor an offline sender can deliver queued messages; automatically resuming all queues whenever either user opens the app needs a separate authenticated lifecycle coordinator and mobile background-delivery design.
2. Public STUN servers are not guaranteed across mobile carrier NATs. A trustworthy STUN/TURN plan and production ICE tests are needed. TURN can relay packets without storing conversation history.
3. Media (up to 80 MB) are app-private but not independently AES-encrypted as files; Android OS file-based encryption protects their storage at rest. Secure wiping cannot be guaranteed on flash storage.
4. Existing Firebase/Cloudinary historical chat messages remain untouched. User-authorized export/migration and safe backend deletion must precede claiming cloud retention is zero.
5. Current group-chat implementation is **unchanged** and still uses the older backend. Migrate groups separately.
6. The chat list itself still uses server-written chat membership documents; only direct-message content is local-first. Some legacy latestText metadata remains from old chats.
7. New Firestore rules are **committed but not deployed**. They must be deployed after emulator tests. With old production rules, peer signaling fails and only the local outbox functions.
8. `pubspec.lock` is refreshed only by running `flutter pub get`. There was no local Flutter SDK available to run `flutter analyze`, build APK, run tests or verify two-device media transfer in this environment.
9. Device-local storage means reinstalling the app or losing the phone can permanently lose chat history and encryption keys unless the user explicitly opts in to a backup design.

## QA checklist before release
1. `flutter pub get`; `flutter analyze`; `flutter test`.
2. Deploy Firestore rules to isolated **staging** environment and test with two authenticated Samsung/Android devices.
3. Send text while disconnected; ensure only Sent is displayed and delivery resumes after reconnect while both screens are open. Verify Read only after receiver receives message.
4. Test edits and withdrawals during connected and disconnected periods; duplicate delivery and connection resets.
5. Send photos, voice, PDF and large video with packet loss / LTE Wi-Fi switches; check integrity, RAM, latency and OS private storage.
6. Blocked recipient, denied Firestore rules, lack of camera/microphone permission, expired auth, canceled uploads, deleted files.
7. Verify no new text or media URLs are written to Firestore, Render or Cloudinary, and that paid gifting still works.
8. Test call launch and return, six wallpapers, RTL, dark mode, app relaunch and local deletion.
9. Audit old Firestore and Cloudinary chat content before purging it; never mass-delete without backed-up opt-in migration.
10. Design TURN and background reliable delivery before public release.

## PowerShell (original working copy)
```powershell
cd C:\Users\AHMED\worldvoice_v2
git fetch origin
git status --short
# Preserve local edits before replacing project files.
git pull --ff-only origin feature/scalable-progress-foundation
flutter pub get
flutter analyze
```
