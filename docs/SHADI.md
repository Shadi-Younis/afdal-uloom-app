# مهام شادي — الأساس، الحسابات، الحماية، النشر

> اقرأ `PROJECT_PLAN.md` أولاً، خصوصاً **القسم 3 (نموذج البيانات)** لأنه العقد الذي يبني عليه الجميع.

## الدور باختصار

شادي هو **قائد المشروع التقني**. يبني الأساس الذي يقف عليه كل التطبيق: هيكل المشروع، وطبقة البيانات، ونظام الحسابات والأدوار، وقواعد الحماية، ولوحة المدير، ثم النشر. ويراجع كود محمد ونور ويقرر متى يُدمج إلى `main`.

هذا القسم هو الأكثر حساسية في المشروع: إذا كان الأساس نظيفاً، يصير شغل محمد ونور أسهل وأسرع بكثير.

---

## المرحلة 1: تجهيز المشروع (الأسبوع 1)

### 1.1 مشروع Firebase

- إنشاء مشروع `afdal-uloom` في Firebase Console.
- التحويل لخطة **Blaze** ووضع **تنبيه ميزانية** في Google Cloud Billing.
- تفعيل: Authentication (Email/Password فقط)، Firestore (production mode)، Storage.
- **عند إنشاء Storage**: اختيار منطقة مشمولة بالحصة المجانية (مثل `us-central1`)، والتأكد من ذلك في صفحة الأسعار وقت الإنشاء.
- إضافة محمد ونور كأعضاء (Project settings ← Users and permissions ← Editor).

### 1.2 مشروع Flutter والريبو

```bash
flutter create afdal_uloom_tilawat --org com.afdaluloom
cd afdal_uloom_tilawat
flutterfire configure            # اختيار android, ios, web
firebase init                    # firestore, storage, functions (TypeScript), hosting, emulators
```

- إنشاء الريبو `afdal-uloom-tilawat` (Private) على GitHub، وإنشاء فرع `develop`.
- **حماية الفروع** في إعدادات GitHub: `main` و`develop` لا يُكتب عليهما إلا عبر PR مع مراجعة واحدة على الأقل.
- إضافة لـ `.gitignore`:

```
serviceAccountKey.json
*.env
functions/lib/
```

### 1.3 هيكل المجلدات

إنشاء كل المجلدات الموجودة في القسم 4 من الخطة العامة، حتى لو كانت فارغة، حتى يعرف كل واحد أين يضع كوده من أول يوم.

### 1.4 التطبيق الأساسي (`lib/app/`)

- **`theme.dart`**: ألوان المدرسة، وخط عربي واضح (Cairo أو Tajawal عبر حزمة google_fonts أو ملفات الخط مباشرة)، وأحجام نصوص مريحة.
- **العربية وRTL** في `main.dart`:

```dart
MaterialApp.router(
  locale: const Locale('ar'),
  supportedLocales: const [Locale('ar')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  routerConfig: router,
  theme: appTheme,
);
```

- **`router.dart`**: مسارات go_router لكل دور (`/login`، `/admin/...`، `/teacher/...`، `/student/...`). التوجيه نفسه حسب الدور يُبنى في المرحلة 2.

### 1.5 الـ Models والـ Interfaces مع النسخ الوهمية ⚠️ أولوية قصوى

هذه أهم مهمة في الأسبوع الأول، لأن محمد ونور ينتظرانها ليبدآ.

**الـ Models** في `lib/core/models/`: `AppUser`، `Halaqa`، `Recording`، `FeedbackNote`، كل واحد مع `fromFirestore` و`toFirestore` حسب نموذج البيانات بالضبط.

**الـ Interfaces** في `lib/core/repositories/`:

```dart
abstract class UsersRepository {
  Stream<AppUser?> watchUser(String uid);
  Stream<List<AppUser>> watchStudentsInHalaqa(String halaqaId);
  Stream<List<Halaqa>> watchTeacherHalaqat(String teacherId);
}

abstract class RecordingsRepository {
  Stream<List<Recording>> watchStudentRecordings(String studentId);
  Stream<List<Recording>> watchPendingPractice(String teacherId);
  Future<Recording?> getRecording(String id);
  Future<String> createRecording(Recording recording);
  Future<void> markFeedbackRead(String recordingId);
  Future<void> markReviewed(String recordingId);
  Future<void> deleteRecording(String recordingId);
}

abstract class FeedbackRepository {
  Stream<List<FeedbackNote>> watchFeedback(String recordingId);
  Future<void> addFeedback(String recordingId, FeedbackNote note);
}
```

**خدمة الملفات** في `lib/core/services/audio_storage_service.dart`:

```dart
abstract class AudioStorageService {
  /// للهاتف: رفع من مسار ملف
  Future<void> uploadFile(String storagePath, String localFilePath,
      {void Function(double progress)? onProgress});

  /// للويب: رفع من bytes (الويب لا يدعم dart:io File)
  Future<void> uploadBytes(String storagePath, Uint8List bytes,
      {required String contentType, void Function(double progress)? onProgress});

  /// رابط مؤقت للتشغيل
  Future<String> getPlayUrl(String storagePath);

  Future<void> delete(String storagePath);
}
```

**النسخ الوهمية (Fakes)**: لكل Interface كلاس مثل `FakeRecordingsRepository` يرجع بيانات تجريبية ثابتة (3 حلقات، 10 طلاب، 20 تسجيلاً، ملاحظات متنوعة، ورابط ملف صوتي تجريبي). ثم **Riverpod Providers** في ملف واحد، بحيث يتم التبديل من Fake إلى Real بتغيير سطر واحد.

**التسليم**: PR إلى `develop` مع رسالة للفريق تشرح كيف يستخدمون الـ Providers.

---

## المرحلة 2: الحسابات والأدوار (الأسبوع 2-3)

### 2.1 Cloud Function: `createUser` (في `functions/src/users.ts`)

دالة callable يستدعيها المدير (أو المعلم لإنشاء طلاب حلقته فقط):

- تتحقق من دور المستدعي من `request.auth.token.role`.
- المعلم لا يقدر ينشئ إلا `student`، وفي حلقة يملكها هو فقط.
- تتحقق أن `username` غير مستخدم.
- تنشئ الحساب في Auth، وتضع Custom Claim `{ role }`، وتنشئ مستند `users/{uid}`.

### 2.2 Cloud Function: `resetPassword`

الطلاب سينسون كلمات السر. المدير أو معلم الطالب يقدر يضع كلمة سر جديدة له.

### 2.3 سكربت المدير الأول (`functions/scripts/bootstrap-admin.ts`)

مشكلة البداية: لا يوجد مدير ليُنشئ الحسابات. سكربت يُشغَّل مرة واحدة من جهاز شادي بمفتاح Service Account (لا يُرفع للريبو أبداً):

```typescript
const user = await getAuth().createUser({
  email: 'shadi@afdal-uloom.app', password: '...', displayName: 'شادي' });
await getAuth().setCustomUserClaims(user.uid, { role: 'admin' });
await getFirestore().doc(`users/${user.uid}`).set({
  username: 'shadi', fullName: 'شادي', role: 'admin', fcmTokens: [],
  createdAt: FieldValue.serverTimestamp() });
```

### 2.4 خدمة الدخول (`lib/core/services/auth_service.dart`)

- `signIn(username, password)`: تحويل اسم المستخدم للإيميل الداخلي ثم الدخول.
- `signOut()`.
- `currentRole`: قراءة الدور من `getIdTokenResult()` ← `claims['role']`.
- رسائل خطأ عربية واضحة ("اسم المستخدم أو كلمة السر غير صحيحة") بدل رسائل Firebase الإنجليزية.

### 2.5 شاشة الدخول (`lib/features/auth/`)

بسيطة وواضحة: شعار المدرسة، اسم المستخدم، كلمة السر، زر دخول، ومؤشر تحميل. بدون "إنشاء حساب".

### 2.6 التوجيه حسب الدور

في `router.dart` باستخدام `redirect`:
- غير مسجّل ← `/login`
- `admin` ← `/admin`
- `teacher` ← `/teacher`
- `student` ← `/student`
- ومنع أي دور من فتح مسارات دور آخر بكتابة الرابط يدوياً (مهم في نسخة الويب).

### 2.7 لوحة المدير (`lib/features/admin/`)

- إدارة المعلمين: إضافة، عرض.
- إدارة الحلقات: إنشاء حلقة وربطها بمعلم.
- إدارة الطلاب: إضافة طالب (اسم، اسم مستخدم، رقم طالب `S023`، حلقة، كلمة سر مبدئية)، ونقله بين الحلقات، وإعادة تعيين كلمة السر.
- **إضافة طلاب دفعة واحدة من ملف CSV** (اختياري لكن مفيد جداً لمدرسة فيها طلاب كثيرون).

---

## المرحلة 3: الدمج والحماية (الأسبوع 4)

### 3.1 الـ Repositories الحقيقية

كتابة `FirestoreRecordingsRepository` وغيرها، ثم التبديل في الـ Providers. شاشات محمد ونور يجب أن تشتغل دون أي تعديل.

### 3.2 قواعد Firestore (`firestore.rules`)

القواعد الأساسية:
- الطالب يقرأ مستنده وتسجيلاته فقط، وينشئ تسجيلات من نوع `practice` لنفسه فقط.
- الطالب يقدر يعدّل `unreadFeedback` فقط في تسجيلاته، ولا أي حقل آخر.
- المعلم يقرأ ويكتب تسجيلات طلاب حلقاته فقط (`resource.data.teacherId == request.auth.uid`).
- الملاحظات (`feedback`) يكتبها المعلم فقط، ويقرأها صاحب التسجيل ومعلمه.
- المدير يقرأ كل شيء.
- لا أحد يغيّر حقل `role` في `users` من التطبيق.

### 3.3 قواعد Storage (`storage.rules`)

- `recordings/{studentId}/{file}`: القراءة للطالب نفسه ومعلمه والمدير.
- الطالب يرفع في مجلده فقط، والملف صوتي فقط (`request.resource.contentType.matches('audio/.*')`)، وبحجم أقل من 30 ميغابايت.

> ملاحظة: قواعد Storage لا تقدر تقرأ Firestore بسهولة لتعرف معلم الطالب. الحل: إضافة claim للمعلم بالحلقات التي يملكها، أو قراءة مستند المستخدم عبر `firestore.get()` المتاحة في قواعد Storage. يُختار الحل المناسب وقت التنفيذ.

### 3.4 اختبار القواعد ⚠️ إلزامي قبل النشر

باستخدام `@firebase/rules-unit-testing` على الـ Emulator. اختبارات على الأقل:
- طالب يحاول قراءة تسجيل طالب آخر ← **مرفوض**
- طالب يحاول كتابة ملاحظة ← **مرفوض**
- معلم يحاول قراءة تسجيل طالب من حلقة غيره ← **مرفوض**
- طالب يحاول تغيير دوره لـ admin ← **مرفوض**
- معلم يكتب ملاحظة على تسجيل طالبه ← **مسموح**

---

## المرحلة 4: التجربة الأولى (الأسبوع 5-6)

- إنشاء حسابات حلقة واحدة حقيقية ومعلمها.
- توزيع النسخة التجريبية: Firebase App Distribution لأندرويد، ونسخة الويب لمن عنده آيفون.
- **جمع الملاحظات وتوزيعها**: ملاحظات المعلمين لمحمد، وملاحظات الطلاب لنور، والباقي لشادي.

---

## المرحلة 5: البنية التحتية (الأسبوع 7-8)

### 5.1 GitHub Actions

ملف `.github/workflows/ci.yml` يشغّل `flutter analyze` و`flutter test` على كل PR، فلا يُدمج كود مكسور.

### 5.2 نشر نسخة الويب

```bash
flutter build web --release
firebase deploy --only hosting
```

هذه النسخة يستخدمها المعلم على كمبيوتر الاستوديو للرفع الجماعي.

---

## المرحلة 6: النشر في المتاجر (الأسبوع 9 فما بعد)

- **سياسة الخصوصية**: صفحة تشرح ما يُجمع (الأسماء، التسجيلات الصوتية) ولماذا ومن يراه. إلزامية للمتجرين، ومهمة جداً لأن التطبيق يتعامل مع أصوات أطفال.
- **نموذج موافقة ولي الأمر** على حفظ تسجيلات ابنه.
- **Google Play**: حساب مطوّر، وتوقيع التطبيق (keystore يُحفظ في مكان آمن خارج الريبو)، والصور والوصف.
- **App Store**: حساب Apple Developer، ويحتاج Mac للبناء. إذا لم يتوفر، يكفي مؤقتاً نسخة الويب لمستخدمي الآيفون.
- **النسخ الاحتياطي**: تفعيل تصدير Firestore أسبوعياً.

---

## مسؤوليات مستمرة طوال المشروع

- **مراجعة PRs** محمد ونور خلال يوم إلى يومين، حتى لا يتعطلوا.
- **حماية نموذج البيانات**: أي طلب تعديل عليه يمر عبر شادي.
- **مراقبة فاتورة Firebase** شهرياً.
- **إدارة الاجتماع الأسبوعي**.

---

## ما يحتاجه شادي من الآخرين

| من | ماذا | متى |
|---|---|---|
| محمد | قائمة السور `surahs.dart` (تُستخدم في لوحة المدير وأماكن أخرى) | الأسبوع 1 |
| نور | `notifications_service.dart` لحفظ `fcmTokens` بعد الدخول | الأسبوع 9 |

## ما يسلّمه شادي للآخرين

| لمن | ماذا | متى |
|---|---|---|
| محمد ونور | Models + Interfaces + Fakes + Providers | **نهاية الأسبوع 1** |
| محمد ونور | Auth يعمل مع التوجيه حسب الدور | الأسبوع 3 |
| محمد ونور | Repositories حقيقية + قواعد الحماية | الأسبوع 4 |

## قائمة الإنجاز

- [ ] مشروع Firebase مع Blaze وتنبيه ميزانية
- [ ] الريبو مع حماية الفروع
- [ ] الهيكل والـ Theme وRTL والـ Router
- [ ] Models + Interfaces + Fakes + Providers
- [ ] `createUser` و`resetPassword` و`bootstrap-admin`
- [ ] شاشة الدخول والتوجيه حسب الدور
- [ ] لوحة المدير (معلمون، حلقات، طلاب، CSV)
- [ ] Repositories حقيقية
- [ ] قواعد Firestore وStorage مع اختباراتها
- [ ] التجربة الأولى مع حلقة واحدة
- [ ] GitHub Actions
- [ ] نشر الويب
- [ ] سياسة الخصوصية ونموذج الموافقة
- [ ] النشر في Google Play وApp Store
- [ ] النسخ الاحتياطي الأسبوعي
