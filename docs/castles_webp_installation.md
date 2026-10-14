# WorldVoice: 10 castle WebP assets installation

The Flutter feature branch already uses `roomCastleWebpAssetForLevel(level)` in `lib/features/rooms/data/room_feature_models.dart` and `Image.asset(..., errorBuilder: SvgPicture.asset(...))` in `room_extras_sheet.dart`. The existing SVG art is a fallback.

**The binary WebP images are supplied separately in `WorldVoice_Castles_Install_10.zip` in the conversation.** This document does not mean those binary assets have been committed to GitHub.

1. Save local changes before switching branches.
2. `git fetch origin` then `git switch feature/scalable-progress-foundation`.
3. Extract the ZIP and run `install_castles.ps1 -ProjectPath <your-local-worldvoice_v2-folder>`.
4. Check `git status`: the 10 new WebP files should appear under `assets/castles/`.
5. Run `flutter pub get`, `flutter analyze`, then `flutter run`.
6. Verify castle tiers 1–5, 6–10, ... 46–50; the UI must use actual WebP, not the SVG fallback.
7. Commit the ten assets on the feature branch only after visual inspection.

## Mission/progression checks

- Room starts at level 1 with `0 / 300 XP` when its authoritative total XP is zero.
- XP required for levels 1,2,3,4,5 is 300,400,700,1000,1300.
- Every five levels selects the next castle asset.
- Claims use the backend `claimVerifiedTask` endpoint; no client-authoritative XP or coins.
- Old room data and deployed backend must be reviewed for progression migration before rollout.
- Do not merge, deploy, or grant paid-coin rewards solely because castle visuals display correctly.

## Runtime and security

- No database schema migration is needed to display these WebP assets.
- No production Firebase, Render, or App Distribution changes are part of asset installation.
- For future scale, keep task writes server-authoritative, idempotent, and avoid hot room documents.
