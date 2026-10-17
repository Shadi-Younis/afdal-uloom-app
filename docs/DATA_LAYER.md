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
| `RecordingRepository` | كل الدوال على التسجيلات **الرسمية**: `watchForStudent(studentId, type: official)`، `watchUnreviewed`، `watchForTeacherSince`، `setSurahAndAyat`، `setReviewed`، `delete` | `watch`، `watchForStudent(studentId, teacherId: uid, type: official)`، `watchUnreviewed(uid)`، `watchForTeacherSince(uid, since)`، `create` (رسمي)، `setSurahAndAyat`، `setReviewed`، `delete` (رسمي) | `watch`، `watchForStudent(uid)` (الرسمي وتدريباته)، `create` (تدريب)، `markFeedbackRead`، `delete` لتدريبه متى شاء |
| `FeedbackRepository` | كل الدوال على التسجيلات الرسمية | `watch`، و`add` و`update` و`delete` على تسجيلات حلقاته الرسمية (كل الملاحظات، ومنها مواضع الشيخ الصوتية) | `watch` على تسجيلاته (قراءة فقط) |

> **مهم للمعلم والمدير:** التدريب ملك الطالب وحده (المهمة 12)، فكل استعلام للمعلم أو المدير يشترط `type: official` (`watchUnreviewed` و`watchForTeacherSince` يفعلان ذلك بأنفسهما)، والمعلم يمرّر أيضاً `teacherId: uid` إلى `watchForStudent`. بدون ذلك ترفض قواعد الحماية الاستعلام كله.

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
- التسجيل الرسمي (والتدريب) يبدأ `reviewed: false`؛ الشيخ يضغط «تمت المراجعة» بعد مراجعة مواضع التسجيل الرسمي (التدريب لا يراه).
- السورة والآيات اختيارية في الرسمي: لا شيء، أو سورة وحدها، أو سورة مع الآيتين (`ayatProblemOf` في `core/utils`، ونفس القاعدة في `firestore.rules`). يكملها المعلم أو المدير لاحقاً بـ«تعديل السورة والآيات» (`setSurahAndAyat`). بلا سورة يُعرض التسجيل «تسجيل» + تاريخه (`recordingTitleOf`).
- **تسجيل بملفين** (`RecordingUploadRequest.sheikhSource`، الرسمي فقط): `storagePath` هو `{id}.mp3` (يكتبه السيرفر فقط)، ويُكتب في المستند `source: "stems"` و`stemPaths` (`StoragePaths.stem`: `{id}.student.{ext}` و`{id}.sheikh.{ext}`)، ثم يُرفع الملفان معاً مع تقدّم كل واحد (`RecordingUploadState.stemProgress`). إذا فشل أحدهما يتوقف الآخر ويُحذف المستند.

**تدريب الطالب** (`/student/practice`، «سجّل تدريباً»): `PracticeRecorderController` يسجّل من الميكروفون عبر `AudioRecorderService` (حزمة `record`): قناة واحدة، `m4a` (AAC) على الهاتف و`webm` (Opus) في المتصفح، بحد أقصى ٣٠ دقيقة (`AppDurations.maxPracticeLength`) وتنبيه عند ٢٥. لا يُرفع شيء قبل «حفظ»: عندها `PracticeSubmitController` يحفظ التسجيل (أو ملفاً اختاره الطالب) عبر `recordingUploadControllerProvider('practice')` بـ `type: practice` و`reviewed: false`. التدريب للطالب وحده: لا يقرؤه المعلم ولا المدير (ولا ملفه)، ولا تُكتب عليه ملاحظات. للتجربة على المتصفح: Edge أو Chrome يسمحان بالميكروفون على `localhost`.

**صفحة الرفع** (`/teacher/upload` للمعلم و`/admin/upload` للمدير، ومع `?student=` من صفحة طالب): `UploadBatchController` في `features/recordings`. لكل ملف صف: الطالب (من طلاب حلقات المعلم فقط، أو كل الطلاب للمدير: `myStudentsProvider`)، والسورة، ومن آية إلى آية (اختيارية)، وتاريخ التسجيل. اسم الملف بصيغة الاستوديو يملأ ما يفهمه (`parseRecordingFileName`). «رفع الكل» يرفع الصفوف المكتملة واحداً بعد الآخر، كل صف عبر `recordingUploadControllerProvider(rowKey)`. لكل صف «ملف واحد (يسار/يمين)» (الافتراضي) أو «ملفين: الطالب + الشيخ»: منطقتان «صوت الطالب» و«صوت الشيخ» (الإفلات عليهما في الويب، أو «اختيار ملف»)، وزر «تبديل». إفلات ملفين على الصف يملأ الاثنين حسب الاسم (student/talmid/طالب أو sheikh/sheich/شيخ) وإلا بالترتيب (`placeStems`)، واسم أي منهما يملأ الحقول الناقصة. قبل الرفع: الملفان موجودان، كل واحد أقل من ١٠٠ ميغابايت، ومدتاهما (من رأس الملف، `AudioDurationReader`: WAV وMP3 وM4A) لا تختلفان أكثر من ثانية.

## تحليل التسجيل الرسمي (`onRecordingUploaded`)

عند وصول ملف تسجيل **رسمي** إلى Storage تحدد الدالة مواضع كلام الشيخ وتكتب لكل موضع ملاحظة `kind: "voice"` فيها `atSecond` و`endSecond` ونص فارغ، وتصنع نسخة السماع المتوسطة `{id}.play.mp3`، وتكتب `analysis` و`playbackPath` و`durationSec`. الحالات: `pending` ثم `done` (أو `mono` إذا لم تكن القناتان منفصلتين، أو `failed`). إعادة التشغيل تستبدل مواضع الشيخ ولا تمس الملاحظات المكتوبة. التدريب لا يُحلَّل.

التحليل يضبط نفسه على كل تسجيل (المهمة 11): الطالب يقرأ أغلب الجلسة، فالقناة التي تغلب في أكثر اللحظات هي قناته؛ إذا كانت اليمنى تبدّل الدالة القناتين وتكتب `analysis.swapped: true`. صوت الطالب في ميكروفون الشيخ (`bleedDb`، مع فرق الـ Gain) يُقاس ولا يُحسب كلاماً للشيخ أبداً، والشيخ هو ما يعلو فوقه بوضوح. إذا لم يعلُ شيء بما يكفي (`separationDb` أقل من ١٠) فلا مواضع (`done` بلا مواضع، والمعلم يضيف ملاحظاته يدوياً). إذا وصلت من سيرفر أحدث حالة لا يعرفها التطبيق فهي تُقرأ `pending` (وتبقى القيمة الأصلية في `RecordingAnalysis.unknownStatus` للسجلات)، و`source` غير معروف يُقرأ `stereo`، فلا تفشل قائمة تسجيلات بسبب مستند واحد. العتبات كلها في `functions/src/lib/voice_analysis.ts` (`ANALYSIS`)، ولتجربتها على ملف في جهازك: [ANALYSE_AUDIO.md](ANALYSE_AUDIO.md).

**تسجيل بملفين:** عند وصول أحد الملفين تنتظر الدالة الآخر. حين يصل الاثنان تحجز الدمج في Transaction (`analysis.status: "merging"`) فلا يُدمج مرتين، وتتأكد أنهما من الجلسة نفسها: فرق المدة ثانية على الأكثر (وإلا `failed` و`error: "stems_length_mismatch"`) والتأخر بينهما ١٠٠ ملّي ثانية على الأكثر، يُقاس من صوت كل واحد في ميكروفون الآخر (وإلا `"stems_misaligned"`؛ ويُحفظ `analysis.stemsLagMs`). ثم تدمجهما (الطالب يسار والشيخ يمين، MP3 بـ 320k) في `storagePath` وتحذف الملفين، ووصول الملف المدموج يشغّل التحليل العادي نفسه. في التطبيق يرى المعلم «جارٍ دمج الملفين…» أو سبب الفشل، والطالب لا يرى التسجيل إلا بعد الدمج (`Recording.hasAudio`)، وعندها هو تسجيل عادي.

## ملفات الصوت في Storage

المسار: `recordings/{studentId}/{recordingId}.{ext}`، ونسخة السماع `recordings/{studentId}/{recordingId}.play.mp3` (يكتبها السيرفر فقط)، وملفا التسجيل بملفين `{recordingId}.student.{ext}` و`{recordingId}.sheikh.{ext}` (يحذفهما السيرفر بعد الدمج). قواعد `storage.rules` تقرأ مستند التسجيل من Firestore:

- **السماع:** المدير، أو معلم الحلقة (بدور معلم)، أو الطالب صاحب التسجيل؛ ونسخة السماع بنفس القاعدة.
- **الرفع:** فقط `uploadedBy` في المستند، إلى نفس `storagePath` بالضبط، ملف صوتي فقط، مرة واحدة (لا كتابة فوق ملف موجود). في التسجيل بملفين: إلى `stemPaths` فقط، ولا أحد يرفع `storagePath` إلا السيرفر.
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

كل تسجيل في الـ Seed يشغّل تلاوة حقيقية للشيخ محمد صديق المنشاوي (مرتّل): الفاتحة أو الإخلاص أو الفلق أو الناس أو آية من أول سورة الملك، وسورته وآياته ومدته تطابق الملف الذي يشغّله. التسجيل `rec-26` (الطالب `s001`) ملف Stereo بقالب الاستوديو (الطالب يسار والشيخ يمين، يبنيه `tool/test_audio/build_fixtures.mjs`)، فتجد له الدالة موضعين لكلام الشيخ. و`rec-28` (الطالب `s001`) الجلسة نفسها بملفين (`source: "stems"`): يرفع الـ Seed الملفين فيدمجهما الـ Emulator ثم يجد الموضعين. و`rec-29` (الطالب `s002`) قناتاه مبدّلتان (الشيخ يسار)، فتبدّلهما الدالة ويظهر للمعلم «تم تبديل الطالب والشيخ تلقائياً». باقي التسجيلات الرسمية صوت واحد في الوسط فيظهر لها «لم نجد قناة الشيخ منفصلة». سبعة تسجيلات رسمية بانتظار المراجعة. الـ Seed يرفع الملفات أربعة أربعة حتى لا يُثقل الـ Functions Emulator. تسجيلات التدريب ملفات `m4a` بقناة واحدة كما يسجّلها الهاتف. الطالب `s001` فيه كل حالات صفحات الطالب: `rec-26` رسمي بمواضع للشيخ لم يقرأها، و`rec-01` رسمي تمت مراجعته، و`rec-27` تدريب تمت مراجعته وعليه ملاحظة مكتوبة (من قبل المهمة 12)، و`rec-20` تدريب، و`rec-30` رسمي بلا سورة ولا آيات. كل حلقة فيها اسم معلمها (`teacherName`). الملفات MP3 مرفوعة إلى Storage Emulator، وتُحفظ خارج المستودع في `C:\dev\test-audio\minshawi\` ولا تُرفع إلى Git (التفاصيل في `tool/seed/README.md`). إذا لم تكن موجودة يرفض الـ Seed العمل ويذكر أمر التنزيل.

يمكن تشغيل الـ Seed أكثر من مرة بأمان. كلمة السر لكل الحسابات `test1234`، والإيميل `<username>@afdal-uloom.app`:

- المدير: `shadi`
- المعلمون: `t01` (حلقة الفجر وحلقة المغرب)، `t02` (حلقة العصر)
- الطلاب: `s001`..`s012`. حلقة المغرب فيها طالبان فقط، و`s012` بلا تسجيلات (لتجربة الحالة الفارغة).

السكربت يرفض العمل إذا لم يكن متصلاً بالـ Emulator، فلا يمكن أن يكتب على المشروع الحقيقي.

## طلب تعديل على نموذج البيانات

لا تغيّر أسماء الحقول أو أنواعها أو المجموعات بنفسك. اكتب لشادي ما تحتاجه ولماذا. إذا وافق، يتم التعديل في نفس الـ PR على: القسم 3 من `PROJECT_PLAN.md`، والـ Model، و`Fields`، و`firestore.rules` واختباراتها، والـ Seed.
