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

- **Models** في `lib/core/models/`: `AppUser`، `Halaqa`، `Recording`، `FeedbackNote`، و`UserRole` و`RecordingType`. التواريخ فيها `DateTime` ولا تستورد Firebase.
- **Providers** في `lib/core/providers/repository_providers.dart`: `userRepositoryProvider`، `halaqaRepositoryProvider`، `recordingRepositoryProvider`، `feedbackRepositoryProvider`. في الاختبارات استبدلها بنسخ وهمية عبر `overrides`.
- **الأخطاء**: كل دالة في الـ Repository ترمي `AppException` فقط، ومعها `AppErrorCode` (`permissionDenied`، `notFound`، `network`، `invalidData`، `unknown`). النص العربي للمستخدم من `errorMessageFor(code)` في `lib/core/utils/error_messages.dart`. لا تعرض نص الخطأ الأصلي أبداً.

## من يستدعي ماذا

| الـ Repository | المدير | المعلم | الطالب |
|---|---|---|---|
| `UserRepository` | كل شيء للقراءة | `watchUser` و`watchStudentsInHalaqa` لطلاب حلقاته | `watchUser` لنفسه |
| | | `addFcmToken` / `removeFcmToken` لنفسه | `addFcmToken` / `removeFcmToken` لنفسه |
| `HalaqaRepository` | كل الدوال (`create`، `rename`) | `watchForTeacher(uid)`، `watch` لحلقاته | `watch` لحلقته |
| `RecordingRepository` | كل الدوال | `watchForStudent(studentId, teacherId: uid)`، `watchPendingPractice(uid)`، `create` (رسمي)، `markReviewed`، `delete` | `watchForStudent(uid)`، `create` (تدريب)، `markFeedbackRead` |
| `FeedbackRepository` | `watch`، `delete` | `watch`، `add` و`delete` لملاحظاته | `watch` على تسجيلاته |

> **مهم للمعلم:** `watchForStudent` يجب أن يُستدعى مع `teacherId: uid`، وإلا ترفض قواعد الحماية الاستعلام كله.

إنشاء الحسابات وتغيير كلمات السر ونقل الطالب بين الحلقات وتغيير معلم الحلقة وإيقاف الحسابات تتم من السيرفر (Cloud Functions) عبر `AccountsService`، وليست في الـ Repositories. التفاصيل في [ACCOUNTS.md](ACCOUNTS.md).

## رفع تسجيل

لا تكتب هذه الخطوات بنفسك: استخدم `recordingUploadControllerProvider` (في `lib/core/application/`)، فهو ينفّذها لتسجيل واحد ويعرض التقدّم والحالة (`RecordingUploadState`):

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

## ملفات الصوت في Storage

المسار: `recordings/{studentId}/{recordingId}.{ext}`. قواعد `storage.rules` تقرأ مستند التسجيل من Firestore:

- **السماع:** المدير، أو معلم الحلقة (بدور معلم)، أو الطالب صاحب التسجيل.
- **الرفع:** فقط `uploadedBy` في المستند، إلى نفس `storagePath` بالضبط، ملف صوتي فقط، مرة واحدة (لا كتابة فوق ملف موجود).
- **الحذف والتعديل:** ممنوعان على التطبيق. عند حذف مستند التسجيل تحذف الدالة `onRecordingDeleted` الملف والملاحظات.

## التشغيل

- `AudioStorageService.getPlaybackUrl(storagePath)` يعطي رابط التحميل العادي (`getDownloadURL()`) ويحتفظ به في الذاكرة طوال الجلسة. لا نخزّن الرابط في Firestore أبداً. تفاصيل هذا القرار في [DEPLOY_NOTES.md](DEPLOY_NOTES.md).
- المشغّل المشترك `RecordingPlayer` (في `core/widgets/common/`) ومعه `recordingPlayerControllerProvider(storagePath)`. منه تقرأ الموضع الحالي (`position`) ومنه تقفز إلى ثانية معيّنة (`seek`).
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

كل تسجيل في الـ Seed يشغّل تلاوة حقيقية للشيخ محمد صديق المنشاوي (مرتّل): الفاتحة أو الإخلاص أو الفلق أو الناس أو آية من أول سورة الملك، وسورته وآياته ومدته تطابق الملف الذي يشغّله. الملفات MP3 مرفوعة إلى Storage Emulator، وتُحفظ خارج المستودع في `C:\dev\test-audio\minshawi\` ولا تُرفع إلى Git (التفاصيل في `tool/seed/README.md`). إذا لم تكن موجودة يرفض الـ Seed العمل ويذكر أمر التنزيل.

يمكن تشغيل الـ Seed أكثر من مرة بأمان. كلمة السر لكل الحسابات `test1234`، والإيميل `<username>@afdal-uloom.app`:

- المدير: `shadi`
- المعلمون: `t01` (حلقة الفجر وحلقة المغرب)، `t02` (حلقة العصر)
- الطلاب: `s001`..`s012`. حلقة المغرب فيها طالبان فقط، و`s012` بلا تسجيلات (لتجربة الحالة الفارغة).

السكربت يرفض العمل إذا لم يكن متصلاً بالـ Emulator، فلا يمكن أن يكتب على المشروع الحقيقي.

## طلب تعديل على نموذج البيانات

لا تغيّر أسماء الحقول أو أنواعها أو المجموعات بنفسك. اكتب لشادي ما تحتاجه ولماذا. إذا وافق، يتم التعديل في نفس الـ PR على: القسم 3 من `PROJECT_PLAN.md`، والـ Model، و`Fields`، و`firestore.rules` واختباراتها، والـ Seed.
