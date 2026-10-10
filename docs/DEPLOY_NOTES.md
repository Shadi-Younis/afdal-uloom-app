# ملاحظات النشر

خطوات وتنبيهات لمن ينشر على المشروع الحقيقي `afdal-al-uloom`. لا ينشر أحد إلا شادي، وبعد أن تنجح كل الاختبارات على الـ Emulators.

## التطوير يبقى على الـ Emulators

النشر لا يغيّر طريقة العمل اليومية: كل تطوير واختبار يكون على الـ Emulator Suite كما في `README.md` (`tool/emulators.ps1` ثم `flutter run --dart-define=USE_EMULATORS=true`). المشروع الحقيقي للاستعمال الفعلي فقط، ولا نكتب فيه بيانات تجربة من سكربتات.

## قبل كل نشر

- أوقف الـ Emulators (الاختبارات تشغّل Emulators خاصة بها على المنافذ نفسها).
- انشر من `main` بعد دمج الـ PR وسحبه: `git checkout main` ثم `git pull`.
- شغّل السكربتات **بنفسك** في نافذة PowerShell خاصة بك، لأنها تسألك وتنتظر إجابتك.
- `firebase login:list` يجب أن يُظهر `shadiyounis7@gmail.com`.

## نشر الخلفية (Backend)

```powershell
powershell -ExecutionPolicy Bypass -File tool/deploy/deploy_backend.ps1
```

ينشر: قواعد Firestore، وفهارس Firestore، وقواعد Storage، وكل Cloud Functions (في `me-west1`).

ما يفحصه السكربت قبل أي نشر، ويتوقف عند أول فشل:

1. لا توجد تعديلات غير محفوظة (`git status` نظيف).
2. أنت على `main`، و`main` مطابق تماماً لـ `origin/main`.
3. Firebase CLI مسجّل الدخول.
4. `flutter analyze` و`flutter test` و`tool/test_rules.ps1` و`tool/test_functions.ps1` كلها ناجحة.
5. يطبع ما سينشره (رقم الـ commit، والقواعد، وعدد الفهارس، وأسماء الدوال ومنطقتها) ويطلب أن تكتب `afdal-al-uloom`. أي شيء آخر يلغي النشر.

ثم ينفّذ `firebase deploy --project afdal-al-uloom --only firestore:rules,firestore:indexes,storage,functions`، وفي النهاية يعرض قائمة الدوال المنشورة ومنطقة كل منها (يجب أن تكون كلها `me-west1`).

أسئلة قد يطرحها Firebase أثناء النشر:

- **«Cloud Storage for Firebase needs an IAM Role to use cross-service rules. Grant the new role?»**: أجب `y` (انظر «قواعد Storage تقرأ من Firestore» أدناه).
- **«How many days do you want to keep container images before they're deleted?»** (أول نشر للدوال فقط): أجب `1`. صور الدوال القديمة في Artifact Registry تُحذف بعد يوم فلا تكلّف.
- في أول نشر يفعّل Firebase تلقائياً واجهات: Cloud Functions وCloud Build وArtifact Registry وCloud Run وEventarc وPub/Sub وCloud Scheduler.

ما حدث فعلاً في أول نشر (10 أكتوبر 2026، الـ commit `84d93cc`)، للرجوع إليه إذا تكرر في مشروع جديد:

1. **المحاولة 1** توقفت بالرسالة «Failed to verify the project has the correct IAM bindings … We failed to modify the IAM policy for the project» قبل نشر أي شيء، وطبعت ثلاثة أوامر `gcloud`. نفّذها شادي (مالك المشروع) في Cloud Shell:

   ```bash
   gcloud projects add-iam-policy-binding afdal-al-uloom --member=serviceAccount:service-650399473840@gcp-sa-pubsub.iam.gserviceaccount.com --role=roles/iam.serviceAccountTokenCreator --condition=None
   gcloud projects add-iam-policy-binding afdal-al-uloom --member=serviceAccount:650399473840-compute@developer.gserviceaccount.com --role=roles/run.invoker --condition=None
   gcloud projects add-iam-policy-binding afdal-al-uloom --member=serviceAccount:650399473840-compute@developer.gserviceaccount.com --role=roles/eventarc.eventReceiver --condition=None
   ```

   نفّذ الأوامر التي يطبعها Firebase أنت، لا هذه النسخة، إذا اختلف المشروع.
2. **المحاولة 2** نشرت القواعد والفهارس و9 دوال، وفشلت `onRecordingDeleted` بخطأ Eventarc «Permission denied while using the Eventarc Service Agent … may take a few minutes». هنا ظهر سؤالا الـ IAM (y) وأيام الصور (1).
3. **المحاولة 3** (بعد نحو 25 دقيقة) بلا أسئلة: نُشرت `onRecordingDeleted` وتخطى Firebase الباقي لأنه لم يتغير.

انتبه: إذا فشل `firebase deploy` في منتصفه يطبع السكربت «Nothing was deployed»، مع أن بعض الأهداف ربما نُشرت. اقرأ مخرجات Firebase نفسها، ثم تحقق بـ `firebase functions:list --project afdal-al-uloom`. إعادة تشغيل السكربت آمنة: ما لم يتغير يُتخطّى.

بعد النشر: الفهارس الجديدة تحتاج بضع دقائق حتى تُبنى. تابع حالتها في Firebase Console ← Firestore ← Indexes حتى تصبح كلها **Enabled**.

## نشر تطبيق الويب

```powershell
powershell -ExecutionPolicy Bypass -File tool/deploy/deploy_web.ps1
```

يفحص الشروط نفسها (git نظيف، `main` مطابق لـ `origin/main`، الدخول إلى Firebase)، ويشغّل `flutter analyze` و`flutter test`، ويطلب كتابة `afdal-al-uloom`، ثم يبني `flutter build web --release` وينفّذ `firebase deploy --only hosting`.

الرابط: https://afdal-al-uloom.web.app

إعدادات الاستضافة في `firebase.json`:

- كل المسارات تُعاد إلى `index.html` (التطبيق يتولى التنقل).
- `index.html` وملفات `js` و`json` و`wasm`: `no-cache`. أسماء ملفات Flutter web ثابتة (بلا hash)، فلو خُزّنت طويلاً لبقي المستخدم على نسخة قديمة بعد النشر. المتصفح يتحقق في كل مرة، وإذا لم يتغير الملف يأخذه من ذاكرته.
- الصور والخطوط: تُخزَّن 7 أيام. تغيير الشعار أو الأيقونات قد يتأخر ظهوره حتى أسبوع.

## نسخة أندرويد (APK)

```powershell
powershell -ExecutionPolicy Bypass -File tool/deploy/build_release_apk.ps1
```

يبني `flutter build apk --release` بدون أي إعداد للـ Emulators (نسخة release لا تتصل بالـ Emulator أبداً)، ويطبع مسار الملف `build\app\outputs\flutter-apk\app-release.apk`.

**تنبيه التوقيع:** إلى أن نجهّز مفتاح رفع حقيقياً (upload keystore) في مهمة النشر على المتجر، تُوقَّع نسخة release **بمفتاح الـ debug**. السكربت يطبع هذا التنبيه في كل مرة. معنى ذلك:

- تصلح للتثبيت على هواتفنا للتجربة فقط.
- لا يقبلها Google Play.
- النسخة التي ستُوقَّع لاحقاً بالمفتاح الحقيقي لا تستطيع تحديث هذه النسخة: يجب حذف التطبيق من الهاتف أولاً.

## التراجع (Rollback)

كل نشر من `main` يُعلَّم بـ tag (مثل `v0.1.0-test`، ثم `v0.2.0`...). للرجوع إلى نسخة سابقة أعد نشر الـ tag السابق:

```powershell
git checkout main
git pull
git fetch --tags
git checkout v0.1.0-test
powershell -ExecutionPolicy Bypass -File tool/deploy/deploy_backend.ps1 -RollbackTag v0.1.0-test
powershell -ExecutionPolicy Bypass -File tool/deploy/deploy_web.ps1 -RollbackTag v0.1.0-test
git checkout main
```

مع `-RollbackTag` يقبل السكربت أن تكون على الـ tag بدل `main`، بشرط أن يكون الـ tag موجوداً على تاريخ `main` وأن يكون git نظيفاً، ثم يفحص ويختبر ويطلب التأكيد كالمعتاد.

انتبه:

- التراجع يرجع الكود والقواعد والدوال فقط. **البيانات لا ترجع** (الحسابات والتسجيلات المحذوفة لا تعود).
- إذا كانت في النسخة الحالية دالة غير موجودة في الـ tag القديم، يسألك Firebase هل يحذفها. اقرأ السؤال قبل الإجابة.
- للويب فقط يوجد طريق أسرع: Firebase Console ← Hosting ← Release history ← النسخة السابقة ← **Rollback**.
- بعد التراجع أصلِح المشكلة على `main` في PR جديد، ثم انشر من `main` كالمعتاد.

## التكاليف التي يجب مراقبتها

المشروع على خطة Blaze مع **تنبيه ميزانية 8 شيكل**. التنبيه يرسل بريداً فقط ولا يوقف الصرف، فراجع الاستهلاك بعد كل نشر وكل أسبوع في البداية: Firebase Console ← Usage and billing، وGoogle Cloud Console ← Billing ← Reports.

ما يُتوقع أن يكلّف (عادةً ضمن الحصة المجانية لمدرسة بحجمنا):

- **Cloud Storage**: حجم ملفات التسجيلات وتنزيلها (سماعها). هذا أول ما سيكبر مع الوقت.
- **Firestore**: القراءات والكتابات. القوائم الحيّة (streams) تقرأ عند كل تغيير.
- **Cloud Functions وCloud Run**: عدد الاستدعاءات ووقتها. `maxInstances` محدد بـ 10 لكل دالة.
- **Cloud Build وArtifact Registry**: عند كل نشر للدوال تُبنى صورة جديدة. سياسة الحذف بعد يوم تمنع تراكم الصور.
- **Cloud Scheduler**: وظيفة واحدة (`cleanupStalledUploads`).
- **Hosting**: حجم موقع الويب والتنزيل منه.

إذا وصل تنبيه الميزانية: افتح Billing ← Reports وانظر أي خدمة سببت الصرف قبل أي تغيير.

## قواعد Storage تقرأ من Firestore

قواعد `storage.rules` تقرأ مستند التسجيل `recordings/{id}` من Firestore لتعرف من يحق له سماع الملف أو رفعه (cross-service rules).

- عند نشر القواعد (`firebase deploy --only storage`) يسأل Firebase إن كنت تريد إعطاء Storage صلاحية قراءة Firestore. **وافق (y).**
- إذا ظهرت الرسالة نفسها في الكونسول (Storage ← Rules) فوافق عليها أيضاً.
- بدون هذه الموافقة يفشل كل `firestore.get()` داخل القواعد، فيُرفض كل سماع وكل رفع للتسجيلات (ما عدا سماع المدير).

## روابط التشغيل (getDownloadURL)

قرار شادي: الطلاب بالغون (+18)، لذلك لا نستخدم روابط موقّعة (signed URLs) ولا دالة `getPlaybackUrl`، ولا نحتاج أي تعديل على صلاحيات IAM.

- التطبيق يطلب رابط التحميل العادي من Storage (`getDownloadURL()`)، ولا يحصل عليه إلا إذا سمحت قاعدة القراءة في `storage.rules` (المدير، أو معلم الحلقة، أو الطالب صاحب التسجيل).
- الرابط لا يُخزَّن في Firestore أبداً؛ نخزّن `storagePath` فقط، والتطبيق يحتفظ بالرابط في الذاكرة طوال الجلسة.
- **المقابل (trade-off):** الرابط لا تنتهي صلاحيته. من يحصل عليه (مثلاً طالب ينسخه ويرسله لغيره) يستطيع سماع الملف بدون تسجيل دخول، إلى أن يُلغى رمز الملف. القواعد تحمي الحصول على الرابط، لا الرابط بعد مشاركته.
- **لإلغاء رابط تسرّب:** الكونسول ← Storage ← افتح الملف ← في تفاصيله "Access token" ← "Revoke". يتوقف الرابط القديم فوراً، والتطبيق يطلب رابطاً جديداً تلقائياً عند الخطأ.

## الدوال (Cloud Functions)

كلها في `me-west1`:

- دوال الحسابات (callable، يستدعيها التطبيق): `createUser`، `resetPassword`، `moveStudent`، `changeHalaqaTeacher`، `setUserDisabled`، `deleteHalaqa`، `deleteUser`، `updateUserProfile`.
- `onRecordingDeleted`: عند حذف مستند تسجيل يحذف ملف الصوت من Storage وكل ملاحظاته (`feedback`).
- `cleanupStalledUploads`: كل يوم الساعة 00:00 UTC يحذف التسجيلات التي مضى عليها أكثر من 24 ساعة ولا يوجد ملفها في Storage (رفع لم يكتمل).

عند النشر:

- أول دالة مجدولة تحتاج Cloud Scheduler API؛ إذا سأل Firebase عن تفعيلها فوافق.
- أول نشر لدالة تعمل على أحداث Firestore قد يفشل برسالة تطلب الانتظار بضع دقائق لإكمال إعداد الصلاحيات (Eventarc). انتظر ثم أعد النشر نفسه.
