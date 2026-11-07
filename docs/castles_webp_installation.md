# WorldVoice castle artwork — 2026-11-07

The ten transparent WebP assets are bundled on `main`. No separate ZIP installation is needed.

## Artwork and progression

- The palace grows from one storey through two and three storeys to wings, towers and a final palace complex.
- All ten assets have native HD resolution (at least 1024 pixels square), preserving transparency and the existing WebP filenames.
- Five levels per appearance, 50 levels total. XP and server-authorized rewards are unchanged.
- The enlarged preview decodes for the device pixel density and scrolls on short screens.
- The existing SVG images remain load-error fallbacks.
- `assets/castles/castle_manifest.json` records dimensions, sizes and SHA-256 checksums.

## Verification

```sh
python3 scripts/verify_castle_assets.py --require-webp
node --test backend/test/room_task_policy.test.js backend/test/gift_hd_assets.test.js backend/test/gift_tier_one_hd.test.js backend/test/gift_tier_two_hd.test.js backend/test/gift_tier_three_hd.test.js
flutter test test/room_castle_progression_test.dart test/classic_gift_visual_test.dart
```

The 104 existing gift images decode at 1254×1254. This update preserves their IDs, prices, categories and artwork; it does not duplicate gifts or grant balances.

## Device test from the original project

```powershell
git pull --ff-only origin main
flutter pub get
.\scripts\run_room_castle_test.ps1
```

The script requires `main` and uses the configured gift-store endpoint. `-GiftPreview` is optional; preview animations do not complete paid gift missions.

On a phone, inspect the room badge, task sheet, all ten palace previews, and gifts in rooms and chat. Real task claims and gift delivery require authenticated device testing against the deployed backend. Asset verification alone does not prove delivery or backend deployment.
