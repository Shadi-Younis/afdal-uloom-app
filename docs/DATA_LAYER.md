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
| `HalaqaRepository` | كل الدوال | `watchForTeacher(uid)`، `watch` لحلقاته | `watch` لحلقته |
| `RecordingRepository` | كل الدوال | `watchForStudent(studentId, teacherId: uid)`، `watchPendingPractice(uid)`، `create` (رسمي)، `markReviewed`، `delete` | `watchForStudent(uid)`، `create` (تدريب)، `markFeedbackRead` |
| `FeedbackRepository` | `watch`، `delete` | `watch`، `add` و`delete` لملاحظاته | `watch` على تسجيلاته |

> **مهم للمعلم:** `watchForStudent` يجب أن يُستدعى مع `teacherId: uid`، وإلا ترفض قواعد الحماية الاستعلام كله.

إنشاء الحسابات وتغيير الأدوار ونقل الطالب بين الحلقات تتم من السيرفر (Cloud Functions) في مهمة لاحقة، وليست في الـ Repositories.

## رفع تسجيل

1. `id = recordingRepository.newId()`
2. `path = StoragePaths.recording(studentId, id, extension: 'm4a')` (الافتراضي `mp3`)
3. `recordingRepository.create(recording)` بنفس الـ `id` و`storagePath: path`
4. رفع الملف إلى `path` في Storage
5. إذا فشل الرفع: `recordingRepository.delete(id)`

`createdAt` يضعه السيرفر دائماً. الامتدادات المسموحة: mp3، m4a، aac، wav، ogg، webm.

## قواعد الحماية واختبارها

القواعد في `firestore.rules`، والأدوار تُقرأ فقط من الـ Custom Claim `role`. بعد أي تعديل على القواعد شغّل:

```powershell
powershell -ExecutionPolicy Bypass -File tool/test_rules.ps1
```

السكربت يشغّل Firestore Emulator جديداً للاختبار فقط ثم يوقفه. أوقف `tool/emulators.ps1` قبله لأن الاثنين يستخدمان المنفذ 8080. الاختبارات في `rules-tests/test/`.

## بيانات تجريبية (Seed)

1. شغّل الـ Emulators: `powershell -ExecutionPolicy Bypass -File tool/emulators.ps1`
2. في نافذة أخرى: `powershell -ExecutionPolicy Bypass -File tool/seed_emulator.ps1`
3. البيانات تظهر في http://localhost:4001 وتبقى محفوظة في `.emulator-data`.

يمكن تشغيل الـ Seed أكثر من مرة بأمان. كلمة السر لكل الحسابات `test1234`، والإيميل `<username>@afdal-uloom.app`:

- المدير: `shadi`
- المعلمون: `t01` (حلقة الفجر وحلقة المغرب)، `t02` (حلقة العصر)
- الطلاب: `s001`..`s012`. حلقة المغرب فيها طالبان فقط، و`s012` بلا تسجيلات (لتجربة الحالة الفارغة).

السكربت يرفض العمل إذا لم يكن متصلاً بالـ Emulator، فلا يمكن أن يكتب على المشروع الحقيقي.

## طلب تعديل على نموذج البيانات

لا تغيّر أسماء الحقول أو أنواعها أو المجموعات بنفسك. اكتب لشادي ما تحتاجه ولماذا. إذا وافق، يتم التعديل في نفس الـ PR على: القسم 3 من `PROJECT_PLAN.md`، والـ Model، و`Fields`، و`firestore.rules` واختباراتها، والـ Seed.
