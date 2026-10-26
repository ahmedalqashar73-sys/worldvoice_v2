# WorldVoice: بداية مجانية دون USB أو PowerShell دائم

**هدف هذه النسخة:** إعادة فتح التطبيق والغرفة الصوتية في أي وقت عن طريق خادم Agora مستقل متاح عبر HTTPS بدل `127.0.0.1:8080`. تظل الغرفة الخضراء القديمة والسبورة كما هي.

## التكاليف والحدود

- خدمة رموز Agora: **Cloudflare Workers Free** (100,000 طلب/يوم، 10ms CPU للطلب وفق حدود سبتمبر 2026). لا تنام بعد 15 دقيقة مثل Render Free، ولكنها محدودة وغير مضمونة بنسبة توفر تجارية.
- Firebase Auth/Firestore: اترك مشروع `worldvoice-37896` على Spark ما دامت الميزات والحصص تسمح بذلك؛ راقب حدود القراءات والكتابات.
- صوت Agora نفسه، ورفع ملفات Cloudinary، والإعلانات: لكل خدمة حصصها وشروطها المنفصلة. مجانية إصدار الرموز ليست ضمانًا بأن بقية التطبيق مجانية دائمًا.
- **خدمات Teacher AI والكويز والمتجر تحتاج الخادم الكامل Node.** يمكن إضافته لاحقًا من خلال Render Free مع العلم أنه ينام عند الخمول، وقد يحتاج دقيقة تقريبًا ليصحو. صوت Agora يبقى مستقلًا عن هذا التأخير.
- Firebase App Distribution مجاني لتوزيع APK على المختبرين، وليس هو استضافة خادم Node.

## 1. احصل على نسخة مستقلة دون تعديل ملفاتك الحالية

افتح Windows PowerShell:

```powershell
cd C:\Users\AHMED\worldvoice_v2
git fetch origin
git worktree add --detach C:\Users\AHMED\worldvoice_free_online_test origin/fix/free-worker-always-available-agora-20260927
cd C:\Users\AHMED\worldvoice_free_online_test\services\agora-token-worker
npm install
npm test
```

إذا كان مجلد `worldvoice_free_online_test` موجودًا، لا تحذفه آليًا. أوقف هنا وافحصه أولًا.

## 2. افتح حساب Cloudflare Workers Free

سجّل بنفسك على https://dash.cloudflare.com/ واختر خطة **Workers Free**. لا تحتاج إلى تبديل خطة Firebase أو تفعيل فوترة Cloud Run من أجل إصدار رموز Agora في هذه النسخة.

**أمان:** شهادة Agora القديمة نُشرت ضمن محادثة سابقة؛ وللإصدار العام أنشئ شهادة بديلة داخل مشروع Agora الصحيح قبل النشر. لا ترسل محتويات الشهادة إلى المحادثة، ولا تضعها في Flutter أو GitHub.

من PowerShell وفي مجلد Worker:

```powershell
npx wrangler login
npx wrangler deploy
npx wrangler secret put AGORA_APP_CERTIFICATE
```

سيفتح تسجيل الدخول متصفحك، وسينشئ `deploy` عنوان `https://...workers.dev`. سيطلب `secret put` الشهادة الجديدة؛ الصقها في الطرفية فقط. لا تجعلها متغيرًا عامًا داخل `wrangler.toml`.

افتح بعدها الرابط الذي أعطتك إياه Cloudflare مع `/health`. يجب أن يعطي `ok: true` **بعد** إضافة الشهادة.

## 3. جرّب إصدارًا يعمل دون كابل USB

من جذر مجلد التجربة:

```powershell
cd C:\Users\AHMED\worldvoice_free_online_test
.\scripts\build_free_android_test.ps1 -WorkerUrl "https://YOUR-WORKER.workers.dev"
```

استبدل المثال بعنوان Cloudflare الحقيقي. ينتج الملف `build\app\outputs\flutter-apk\app-release.apk` بعد اكتمال الفحص والبناء.

يمكن تثبيته على هاتف Android ثم **فصل الكابل واللابتوب**، وفتح التطبيق والغرفة عدة مرات عبر Wi-Fi ثم بيانات الهاتف. اختبر الميكروفون مع شخص آخر. إذا ظهرت مشكلة في الإذن، لا تغير Firebase أو Agora عشوائيًا؛ افحص استجابة Worker وFirestore أولًا.

## 4. فعّل الميزات الباقية مجانًا أثناء الاختبار (اختياري)

Render Free يسمح باستضافة خادم `backend` الأصلي بـ Node. في Render اربط GitHub واختر الفرع الحالي ومجلد `backend`، ثم خطة Free، أو استخدم `render.yaml`. لا تستخدم عنوانًا محليًا. أضف `firebase-admin.json` الخاص بمشروعك فقط إلى **Render Secret Files** باسم `firebase-admin.json` (المسار داخل Render هو `/etc/secrets/firebase-admin.json`). ولا ترفعه إطلاقًا إلى GitHub. عرّف شهادة Agora **الجديدة** سرًا داخل Render أيضًا، وحدد معرف المشروع.

عند جاهزية رابط Render `https://...onrender.com`، ضع في إعدادات Cloudflare Worker متغير `AUX_BACKEND_URL` بهذا الرابط عبر لوحة Workers Settings، ثم أعد نشر إعداداته. سيحوّل Worker طلبات Teacher AI والكويز والمتجر إليه تلقائيًا، **دون الحاجة لبناء APK من جديد**. يجب فحص صلاحيات Firestore واختبار جميع الميزات قبل توزيع التطبيق.

**مهم:** Render Free ينام بعد 15 دقيقة دون طلبات ويحتاج إلى وقت للاستيقاظ؛ لا تعتمد عليه وحده لرموز الصوت. وقد يُوقف الخدمة عند تجاوز الاستخدام المجاني.

## 5. وزّع نسخة الاختبار على الأصدقاء بعد نجاح التجربة

```powershell
npm install -g firebase-tools
firebase login
cd C:\Users\AHMED\worldvoice_free_online_test
.\scripts\distribute_android_test.ps1 -Testers "friend@example.com"
```

يستخدم Firebase App Distribution الموجود ضمن خطة Spark دون رسوم لهذه الميزة. التوزيع للمختبرين ليس نشرًا عامًا في Google Play.

## الإعلانات

حزمة Google Mobile Ads موجودة أصلًا في WorldVoice، لكن معرّف Android الحالي تجريبي. لا تستعمل الإعلانات الحقيقية ولا تضغطها خلال الاختبار. الإيرادات تتطلب حساب AdMob ومعرّفات تطبيق وإعلانات حقيقية وموافقة مطلوبة عند النشر، والتزام إعدادات الخصوصية.
