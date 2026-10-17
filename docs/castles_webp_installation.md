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
flutter test
.\scripts\run_room_castle_test.ps1
```

Do not run the local branch switch when `git status` reports uncommitted work without saving it first.


## مراجعة الإكمال — 15 أكتوبر 2026

- تم التحقق من الصور العشر الأصلية وأسمائها وأبعادها وشفافيتها وبصماتها في manifest. لا حاجة لإعادة فك ZIP فوق الملفات الصحيحة الموجودة.
- أضيف منع ترحيل السجل إذا كان المستوى المحفوظ أعلى من المستوى الذي تفسره XP، أو كان المستوى ذا صيغة غير صحيحة. يعود الخادم بخطأ 409 دون تعديل الغرفة أو إنشاء مطالبة أو مكافأة؛ لا نخمن نقاطًا ناقصة ولا نصفرها.
- الاختبارات المحلية في محاكي Firestore: 74 اختبار backend ناجحًا و24 اختبار قواعد ناجحًا، دون اختبارات متخطاة. يشغّل CI الآن `flutter test` كاملًا، و`npm test` كاملًا داخل المحاكي. تُراجع النتيجة النهائية والبناء في فحوص PR93.
- سكربت PowerShell الموجود يشغل pub get ثم analyze ثم test ثم run، ويتحقق من الفرع والصور. وضع معاينة الهدايا أصبح اختياريًا عبر `-GiftPreview`؛ المعاينة لا تثبت مهمة إرسال هدية حقيقية.

### ملفات هذه المراجعة

- `.github/workflows/validate.yml`: اختبارات Flutter والخادم كاملة.
- `backend/src/room_task_policy.js`: حماية تقدم الغرف غير المتسق.
- `backend/test/room_task_policy.test.js`: حالات المستوى الناقص والمتعارض.
- `backend/test/room_task_routes.test.js`: التحقق من عدم تغيير البيانات أو منح جوائز عند التعارض.
- `scripts/run_room_castle_test.ps1`: اختبار قبل التشغيل ومعاينة هدايا اختيارية.
- `docs/castles_webp_installation.md`: التقرير وأوامر التجربة.

ملفات التنفيذ السابقة تشمل `assets/castles/`، ونماذج الغرف وخدماتها ولوحة المهام في `lib/features/rooms/`، ومسارات المهام في `backend/src/room_task_routes.js`، ودورة المكافآت والشارات في `lib/features/engagement/` و`backend/src/engagement_*.js`. تفصيلها في `docs/room-castles-delivery-20261014.md` و`docs/engagement-cycle-20261015.md`.

### ما بقي فعليًا

- مراجعة سجلات غرف الإنتاج قبل تفعيل الترحيل. الاختبارات تثبت قواعد التحويل والحماية، ولا تثبت سلامة كل سجل إنتاجي لم يُقرأ.
- نشر الخادم المحدّث بعد الموافقة والمراجعة. لا يعتبر إنشاء APK نشرًا للخادم، ولا تغيّر هذه المراجعة Render أو Firebase أو main أو أرصدة الكوينز.
- على الجوال: وضوح القلاع العشر وتكبيرها، عدم تداخلها مع المقاعد والخلفية، العربية وتكبير الخط، حضور حسابين وإعادة الاتصال، والهدايا والمطالبات بعد توفر الخادم الجديد.
- ترتيب التحدث الحالي وصفي، ومكافأة الخلفية تعتمد على الكتالوج؛ لا توجد مكافأة مالية مبنية على وقت يتتبعه الهاتف. جمهور مكافأة القلعة الأكبر من 1000 يحتاج معالجة إضافية قبل دعمه.
