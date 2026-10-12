# طبقة البيانات

هذا الملف يشرح كيف تصل الشاشات إلى البيانات، ومن يحق له ماذا. نموذج البيانات نفسه في القسم 3 من [PROJECT_PLAN.md](PROJECT_PLAN.md).

## الطبقات

```
الشاشة (presentation)
   ↓  تقرأ الحالة وترسل الأحداث فقط
الـ Controller (application)
   ↓  يستدعي الـ Repository عبر الـ Provider
الـ Repository (interface في lib/core/repositories/)
   ↓
التطبيق الفعلي على Firestore (lib/core/data/)
```

- **Models** في `lib/core/models/`: `AppUser`، `Halaqa`، `Recording` (ومعه `RecordingAnalysis`)، `FeedbackNote`، و`UserRole` و`RecordingType` و`AnalysisStatus` و`FeedbackKind`. التواريخ فيها `DateTime` ولا تستورد Firebase.
- **Providers** في `lib/core/providers/repository_providers.dart`: `userRepositoryProvider`، `halaqaRepositoryProvider`، `recordingRepositoryProvider`، `feedbackRepositoryProvider`. في الاختبارات استبدلها بنسخ وهمية عبر `overrides`.
- **الأخطاء**: كل دالة في الـ Repository ترمي `AppException` فقط، ومعها `AppErrorCode` (`permissionDenied`، `notFound`، `network`، `invalidData`، `unknown`). النص العربي للمستخدم من `errorMessageFor(code)` في `lib/core/utils/error_messages.dart`. لا تعرض نص الخطأ الأصلي أبداً.

## من يستدعي ماذا

| الـ Repository | المدير | المعلم | الطالب |
|---|---|---|---|
| `UserRepository` | كل شيء للقراءة | `watchUser` و`watchStudentsInHalaqa` لطلاب حلقاته | `watchUser` لنفسه |
| | | `addFcmToken` / `removeFcmToken` لنفسه | `addFcmToken` / `removeFcmToken` لنفسه |
| `HalaqaRepository` | كل الدوال (`create`، `rename`)؛ الحذف عبر الدالة `deleteHalaqa` فقط (`AccountsService`) | `watchForTeacher(uid)`، `watch` لحلقاته | `watch` لحلقته (ومنها اسم شيخه `teacherName`) |
| `RecordingRepository` | كل الدوال | `watch`، `watchForStudent(studentId, teacherId: uid)`، `watchUnreviewed(uid)` (و`type:` اختياري)، `watchForTeacherSince(uid, since)`، `create` (رسمي)، `setReviewed`، `delete` | `watch`، `watchForStudent(uid)`، `create` (تدريب)، `markFeedbackRead`، `delete` لتدريبه قبل أن يراجعه الشيخ |
| `FeedbackRepository` | كل الدوال | `watch`، و`add` و`update` و`delete` على تسجيلات حلقاته (كل الملاحظات، ومنها مواضع الشيخ الصوتية) | `watch` على تسجيلاته (قراءة فقط) |

> **مهم للمعلم:** `watchForStudent` يجب أن يُستدعى مع `teacherId: uid`، وإلا ترفض قواعد الحماية الاستعلام كله.

**اسم الشيخ للطالب:** الطالب لا يقرأ ملفات المعلمين (`users`)، فاسم معلم الحلقة منسوخ في `halaqat/{id}.teacherName`. يكتبه `HalaqaRepository.create` من اسم المعلم (والقواعد تتحقق أنه يساويه)، ويحدّثه السيرفر في `changeHalaqaTeacher` و`updateUserProfile`. في التطبيق: `studentHalaqaProvider` (حلقة الطالب) و`sheikhName(teacherName)` («الشيخ محمود»، أو «الشيخ» إذا لم يُعرف الاسم بعد).

إنشاء الحسابات وتغيير كلمات السر ونقل الطالب بين الحلقات وتغيير معلم الحلقة وإيقاف الحسابات تتم من السيرفر (Cloud Functions) عبر `AccountsService`، وليست في الـ Repositories. التفاصيل في [ACCOUNTS.md](ACCOUNTS.md).

## رفع تسجيل

لا تكتب هذه الخطوات بنفسك: استخدم `recordingUploadControllerProvider(key)` (في `lib/core/application/`، واحد لكل رفع)، فهو ينفّذها لتسجيل واحد ويعرض التقدّم والحالة (`RecordingUploadState`):

1. `id = recordingRepository.newId()`
2. `path = StoragePaths.recording(studentId, id, extension: 'm4a')` (الافتراضي `mp3`)
3. `recordingRepository.create(recording)` بنفس الـ `id` و`storagePath: path`
4. رفع الملف إلى `path` في Storage عبر `AudioStorageService.upload` (مع التقدّم وإمكانية الإلغاء)
5. إذا فشل الرفع أو أُلغي: `recordingRepository.delete(id)`

- `createdAt` يضعه السيرفر دائماً.
- الامتدادات المسموحة ونوع المحتوى لكل منها في `AudioFormats.contentTypes`: mp3، m4a، aac، wav، ogg، webm.
- الحد الأقصى لحجم الملف **أقل من ١٠٠ ميغابايت** (`AudioFormats.maxUploadBytes`، ونفس الرقم في `storage.rules`).
- على الموبايل نرفع ملفاً (`FileAudioSource`)، وعلى الويب بايتات (`BytesAudioSource`).
- إذا بقي مستند بلا ملف (انقطع التطبيق أثناء الرفع)، تحذفه الدالة `cleanupStalledUploads` بعد ٢٤ ساعة.
- التسجيل الرسمي (والتدريب) يبدأ `reviewed: false`؛ الشيخ يضغط «تمت المراجعة» بعد مراجعة مواضعه.

**تدريب الطالب** (`/student/practice`، «سجّل تدريباً»): `PracticeRecorderController` يسجّل من الميكروفون عبر `AudioRecorderService` (حزمة `record`): قناة واحدة، `m4a` (AAC) على الهاتف و`webm` (Opus) في المتصفح، بحد أقصى ٣٠ دقيقة (`AppDurations.maxPracticeLength`) وتنبيه عند ٢٥. لا يُرفع شيء قبل «إرسال للشيخ»: عندها `PracticeSubmitController` يرسل التسجيل (أو ملفاً اختاره الطالب) عبر `recordingUploadControllerProvider('practice')` بـ `type: practice` و`reviewed: false`. للتجربة على المتصفح: Edge أو Chrome يسمحان بالميكروفون على `localhost`.

**صفحة الرفع** (`/teacher/upload` للمعلم و`/admin/upload` للمدير، ومع `?student=` من صفحة طالب): `UploadBatchController` في `features/recordings`. لكل ملف صف: الطالب (من طلاب حلقات المعلم فقط، أو كل الطلاب للمدير: `myStudentsProvider`)، والسورة، ومن آية إلى آية، وتاريخ التسجيل. اسم الملف بصيغة الاستوديو يملأ ما يفهمه (`parseRecordingFileName`). «رفع الكل» يرفع الصفوف المكتملة واحداً بعد الآخر، كل صف عبر `recordingUploadControllerProvider(rowKey)`.

## تحليل التسجيل الرسمي (`onRecordingUploaded`)

عند وصول ملف تسجيل **رسمي** إلى Storage تحدد الدالة مواضع كلام الشيخ (القناة اليمنى أعلى بوضوح من اليسرى) وتكتب لكل موضع ملاحظة `kind: "voice"` فيها `atSecond` و`endSecond` ونص فارغ، وتصنع نسخة السماع المتوسطة `{id}.play.mp3`، وتكتب `analysis` و`playbackPath` و`durationSec`. الحالات: `pending` ثم `done` (أو `mono` إذا لم تكن القناتان منفصلتين، أو `failed`). إعادة التشغيل تستبدل مواضع الشيخ ولا تمس الملاحظات المكتوبة. التدريب لا يُحلَّل. العتبات كلها في `functions/src/lib/voice_analysis.ts` (`ANALYSIS`).

## ملفات الصوت في Storage

المسار: `recordings/{studentId}/{recordingId}.{ext}`، ونسخة السماع `recordings/{studentId}/{recordingId}.play.mp3` (يكتبها السيرفر فقط). قواعد `storage.rules` تقرأ مستند التسجيل من Firestore:

- **السماع:** المدير، أو معلم الحلقة (بدور معلم)، أو الطالب صاحب التسجيل؛ ونسخة السماع بنفس القاعدة.
- **الرفع:** فقط `uploadedBy` في المستند، إلى نفس `storagePath` بالضبط، ملف صوتي فقط، مرة واحدة (لا كتابة فوق ملف موجود).
- **الحذف والتعديل:** ممنوعان على التطبيق. عند حذف مستند التسجيل تحذف الدالة `onRecordingDeleted` الملف والملاحظات.

## التشغيل

- المشغّل يشغّل `recording.playablePath`: نسخة السماع إذا وُجدت، وإلا الأصل.
- `AudioStorageService.getPlaybackUrl(storagePath)` يعطي رابط التحميل العادي (`getDownloadURL()`) ويحتفظ به في الذاكرة طوال الجلسة. لا نخزّن الرابط في Firestore أبداً. تفاصيل هذا القرار في [DEPLOY_NOTES.md](DEPLOY_NOTES.md).
- المشغّل المشترك `RecordingPlayer` (في `core/widgets/common/`) ومعه `recordingPlayerControllerProvider(source)`، و`source` إما `StoredPlayback(storagePath)` لتسجيل في Storage أو `LocalPlayback(uri)` لتسجيل على الجهاز لم يُرسل بعد. منه تقرأ الموضع الحالي (`position`) ومنه تقفز إلى ثانية معيّنة (`seek`).
- إذا فشل تحميل الصوت يعيد المحاولة مرة واحدة برابط جديد من نفس الموضع.
- مشغّل واحد فقط في نفس الوقت، ويتوقف عند الخروج من الشاشة.
- **الاتجاه:** شريط التقدّم يتبع اتجاه Material في العربية، فيمتلئ من اليمين إلى اليسار. الوقت الحالي على اليمين والمدة الكاملة على اليسار، وزر "رجوع ٥ ثوانٍ" على اليمين و"تقديم ٥ ثوانٍ" على اليسار.

## قواعد الحماية واختبارها

القواعد في `firestore.rules`، والأدوار تُقرأ فقط من الـ Custom Claim `role`. بعد أي تعديل على القواعد شغّل:

```powershell
powershell -ExecutionPolicy Bypass -File tool/test_rules.ps1
```

السكربت يشغّل Firestore وStorage Emulators جديدة للاختبار فقط ثم يوقفها. أوقف `tool/emulators.ps1` قبله لأن الاثنين يستخدمان المنافذ 8080 و9199. الاختبارات في `rules-tests/test/` (قواعد Storage في `storage.test.ts`).

## بيانات تجريبية (Seed)

1. شغّل الـ Emulators: `powershell -ExecutionPolicy Bypass -File tool/emulators.ps1`
2. في نافذة أخرى، مرة واحدة فقط، نزّل ملفات التلاوة: `powershell -ExecutionPolicy Bypass -File tool/seed/download_test_audio.ps1`
3. ثم: `powershell -ExecutionPolicy Bypass -File tool/seed_emulator.ps1`
4. البيانات تظهر في http://localhost:4001 وتبقى محفوظة في `.emulator-data`.

كل تسجيل في الـ Seed يشغّل تلاوة حقيقية للشيخ محمد صديق المنشاوي (مرتّل): الفاتحة أو الإخلاص أو الفلق أو الناس أو آية من أول سورة الملك، وسورته وآياته ومدته تطابق الملف الذي يشغّله. التسجيل `rec-26` (الطالب `s001`) ملف Stereo بقالب الاستوديو (الطالب يسار والشيخ يمين، يبنيه `tool/test_audio/build_fixtures.mjs`)، فتجد له الدالة موضعين لكلام الشيخ؛ باقي التسجيلات الرسمية صوت واحد في الوسط فيظهر لها «لم نجد قناة الشيخ منفصلة». أربعة تسجيلات رسمية بانتظار المراجعة. تسجيلات التدريب ملفات `m4a` بقناة واحدة كما يسجّلها الهاتف. الطالب `s001` فيه كل حالات صفحات الطالب: `rec-26` رسمي بمواضع للشيخ لم يقرأها، و`rec-01` رسمي تمت مراجعته، و`rec-27` تدريب تمت مراجعته وعليه ملاحظة مكتوبة، و`rec-20` تدريب بانتظار الشيخ. كل حلقة فيها اسم معلمها (`teacherName`). الملفات MP3 مرفوعة إلى Storage Emulator، وتُحفظ خارج المستودع في `C:\dev\test-audio\minshawi\` ولا تُرفع إلى Git (التفاصيل في `tool/seed/README.md`). إذا لم تكن موجودة يرفض الـ Seed العمل ويذكر أمر التنزيل.

يمكن تشغيل الـ Seed أكثر من مرة بأمان. كلمة السر لكل الحسابات `test1234`، والإيميل `<username>@afdal-uloom.app`:

- المدير: `shadi`
- المعلمون: `t01` (حلقة الفجر وحلقة المغرب)، `t02` (حلقة العصر)
- الطلاب: `s001`..`s012`. حلقة المغرب فيها طالبان فقط، و`s012` بلا تسجيلات (لتجربة الحالة الفارغة).

السكربت يرفض العمل إذا لم يكن متصلاً بالـ Emulator، فلا يمكن أن يكتب على المشروع الحقيقي.

## طلب تعديل على نموذج البيانات

لا تغيّر أسماء الحقول أو أنواعها أو المجموعات بنفسك. اكتب لشادي ما تحتاجه ولماذا. إذا وافق، يتم التعديل في نفس الـ PR على: القسم 3 من `PROJECT_PLAN.md`، والـ Model، و`Fields`، و`firestore.rules` واختباراتها، والـ Seed.
