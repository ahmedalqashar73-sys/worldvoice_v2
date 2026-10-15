# WorldVoice — Castle WebP assets: integration status (2026-10-15)

**The ten original 512×512 transparent WebP castles are already committed to this branch. Do not manually install or reupload the ZIP.** Their checksums and filenames are recorded in `assets/castles/castle_manifest.json`. The previous ZIP-install instructions are obsolete.

## Integrated paths and behavior

- `assets/castles/castle_01_lv01-05.webp` through `castle_10_lv46-50.webp`.
- `pubspec.yaml` includes `assets/castles/`.
- `roomCastleWebpAssetForLevel(level)` selects the file for every five-level tier.
- Existing SVG artwork remains a fallback if a WebP fails to load.
- Room castle artwork is visible in the room header and the task sheet, with an enlarged preview.
- `scripts/verify_castle_assets.py --require-webp` checks all ten files against the manifest during CI.

## Progression and economy

- 50 room levels and ten castle looks; initial room: level 1, 0/300 XP.
- Per-level XP: 300, 400, 700, 1000, then +300 XP per further level.
- Firestore documents retain progress and must be versioned; client-side XP and economic rewards are never trusted.
- Legacy progress requires server-authoritative migration and review of real room records.
- XP rewards and castle milestones are non-monetary. No coin minting or paid gift grants.

## Current validation and deployment boundary

- Validate WorldVoice runs Flutter analysis/tests, backend tests, Firestore emulator and APK build.
- The APK is published to GitHub Actions as `WorldVoice-castles-development-apk`.
- The APK points at the currently deployed `worldvoice-v2.onrender.com` server. **That production service uses an older Git branch**. The new task/engagement endpoints therefore cannot be considered available in production simply because the APK builds.
- This branch is not merged into `main`. No Render/Firebase deployment or migration is implied.
- Before enabling live XP claims, check existing production data, apply a staged deployment/rollback plan, and test with two phones.

## Downloading and testing the APK

Open the successful GitHub Actions run of **Validate WorldVoice**, select **WorldVoice-castles-development-apk** under Artifacts, extract `app-debug.apk`, and install on an Android test device.

For local source tests (optional):

```powershell
git fetch origin
git switch feature/scalable-progress-foundation
flutter pub get
flutter analyze
flutter run
```

Do not run the local branch switch when `git status` reports uncommitted work without saving it first.
