# WorldVoice — approved first category (30 Classic Premium gifts)

**Status:** 2026-09-29 staging UI preview. Same existing `UnifiedGiftPanel` in
one-to-one chat, Live and voice rooms. No second catalog/store implementation.

## Source and rendering

- **One source of truth:** `assets/gifts/classic_premium_1_50.json`.
  Exactly 30 approved IDs, ordered from 1 to 50 coins. Local metadata is
  presentation-only; it cannot enable purchases or decide paid prices.
- **No tile frames:** `ClassicGiftVisual` draws a transparent emerald halo
  around each image/glyph. Each item shows its localized name and gold coin price
  underneath; selected state uses a short emerald underline rather than a box.
- **Motion:** 30 effect labels in JSON drive motion families such as float,
  pulse, orbit, feather drift, butterfly flight and phoenix glow.
  The `Preview gift effect` control opens an explicitly free local animation.
  The screen currently uses platform emoji as **temporary art**, NOT completed
  custom 3D assets. `previewUrl` accepts a reviewed HTTPS image and the actual
  event `animationUrl` may provide a compatible animated image (e.g. GIF).
  Real rigged 3D and specialist effects still require approved assets.
- **One shared API:** `RoomFeatureService.sendContextGift` is unchanged.
  Active status and final price come only from backend-published `store_items`.
  First-tier local previews and new staging docs default to **inactive**.
  Production money switches and Firestore rules are not deployed here.

## Three presentation surfaces

| Surface | Preview and picker | Actual paid gift |
|---|---|---|
| Voice room | Existing tools > Gifts picker and existing shared room overlay | Existing verified backend path only when monetary gates pass |
| One-to-one chat | Existing conversation gift picker plus Chat-tab 30-gift preview entry; shared art and genuine new-event overlay | Existing verified backend path only when monetary gates pass and mutual-follower membership is valid |
| Live | Same existing picker for existing Live rooms plus Live-tab 30-gift preview entry | **Blocked** by backend 501 pending real verified Agora live-session membership/ACL; never imply it succeeded |

Do not conflate client-side preview with a delivered present. Testing animations
must never decrement wallet balances or create Firestore gift events.

## Safely try it on Android

1. Check the existing room-feature branch and preserve local modifications
   before switching. `flutter pub get`; `flutter run` with the current public
   Agora project and Worker launch flags if needed.
2. Voice room > Gifts > 1–50: all 30 previews should be present. Tap
   butterflies, royal rose, bouquet and phoenix; press Preview. No coin changes.
3. Chat tab > gift icon: the **same** 30 should appear. Live tab > Preview the
   30 gifts: the **same** list should appear even without real live broadcasts.
4. For any already published paid catalog entry, verify that the server still
   decides the displayed active state and real price. With disabled economy
   flags, **Send** remains disabled in all three.
5. Real-device quality check still needed: Arabic labels fit smaller phones,
   overlay doesn't cover critical controls, and existing room audio survives.
   The GIF/3D production art pipeline is not complete yet.

## Optional staging-only Firestore draft (not a deployment)

`node backend/scripts/seed-classic-gifts.mjs` prints all 30 proposed draft
documents. The script may create them only for an emulator or explicit
staging/test project using matching `--confirm-project`, and only while
`economy_config/current.enabled == false`. It uses Firestore `create()`
and never overwrites an existing document, price or activation status.

## Validation

`test/classic_gift_catalog_test.dart` checks count, pricing range, uniqueness
and server-authoritative published prices. `test/classic_gift_visual_test.dart`
checks non-framed Flutter rendering. Backend checks consume the same JSON.
The Flutter, backend and Firestore CI must pass before updating a test phone.
No production deployment is included.
