# تطبيق تلاوات مدرسة أفضل العلوم

تطبيق (`afdal_uloom_tilawat`) يحفظ لكل طالب تلاواته المسجّلة في استوديو المدرسة مع ملاحظات معلمه عليها، ويسمح للطالب بتسجيل تلاوات تدريبية وإرسالها للمعلم.

## المتطلبات

- **Flutter 3.47.6** (قناة stable)، ومعه Dart 3.13.5.
- يجب أن يستخدم كل أعضاء الفريق نفس الإصدار **Flutter 3.47.x** حتى لا تختلف نتائج البناء والتحليل بيننا.
- حزمة `google_fonts` مثبّتة على الإصدار **8.2.1** لأن الإصدار 9.0.0 يعتمد على حزمة `material_ui` التي لا تتوافق أنواعها مع Material الموجودة في Flutter 3.47.

## التشغيل

```bash
flutter pub get
flutter run -d chrome
```

## التشغيل مع Firebase Emulator

> **لا أحد يجرّب على مشروع Firebase الحقيقي.** كل التجارب والتطوير تتم على الـ Emulator فقط.

يحتاج Node و Firebase CLI و Java 11 أو أحدث.

1. تشغيل الـ Emulators (الطريقة الافتراضية):

   ```powershell
   powershell -ExecutionPolicy Bypass -File tool/emulators.ps1
   ```

   السكربت يبني الـ Functions ثم يشغّل الـ Emulators مع حفظ البيانات في مجلد `.emulator-data` (غير مرفوع على Git).
   للإيقاف اضغط **Ctrl+C** مرة واحدة وانتظر حتى تظهر `Export complete`، فتُحفظ البيانات وتعود في التشغيل التالي.

   واجهة الـ Emulator على http://localhost:4001

2. تشغيل التطبيق على Edge مع الـ Emulators:

   ```bash
   flutter run -d edge --dart-define=USE_EMULATORS=true
   ```

3. تشغيل التطبيق على هاتف حقيقي (نفس شبكة الـ Wi-Fi) مع عنوان IP جهازك على الشبكة المحلية:

   ```bash
   flutter run -d <device-id> --dart-define=USE_EMULATORS=true --dart-define=EMULATOR_HOST=<LAN IP>
   ```

على محاكي أندرويد لا حاجة لـ `EMULATOR_HOST` (القيمة الافتراضية `10.0.2.2`). بدون `USE_EMULATORS=true` يتصل التطبيق بالمشروع الحقيقي، ونسخة release لا تتصل بالـ Emulator أبداً.

### بيانات تجريبية

بعد تشغيل الـ Emulators، في نافذة أخرى:

```powershell
powershell -ExecutionPolicy Bypass -File tool/seed/download_test_audio.ps1   # مرة واحدة: تلاوات المنشاوي خارج المستودع
powershell -ExecutionPolicy Bypass -File tool/seed_emulator.ps1
```

ينشئ مديراً ومعلمَين و3 حلقات و12 طالباً مع تسجيلات وملاحظات، ويمكن تشغيله أكثر من مرة بأمان. البيانات تبقى محفوظة في `.emulator-data`.

حسابات التجربة (**على الـ Emulator فقط**، كلمة السر `test1234` للجميع):

| اسم المستخدم | الدور |
|---|---|
| `shadi` | مدير |
| `t01` | معلم (حلقة الفجر وحلقة المغرب) |
| `s001` | طالب |

اختبار دوال السيرفر (Cloud Functions) على الـ Emulators (أوقف `tool/emulators.ps1` أولاً):

```powershell
powershell -ExecutionPolicy Bypass -File tool/test_functions.ps1
```

اختبار قواعد الحماية (أوقف الـ Emulators أولاً لأن الاختبار يستخدم المنفذ 8080):

```powershell
powershell -ExecutionPolicy Bypass -File tool/test_rules.ps1
```

اختبار سريع للربط مع الـ Emulators (يعمل فقط مع `USE_EMULATORS=true`):

```bash
flutter test integration_test/emulator_smoke_test.dart -d <device-id> --dart-define=USE_EMULATORS=true --dart-define=EMULATOR_HOST=<LAN IP>
```

## طريقة العمل على Git

- `main` هو الفرع الوحيد الدائم (فرع `develop` لم يعد مستخدماً).
- كل مهمة في فرع جديد من `main`: `git checkout main && git pull` ثم `git checkout -b feature/<اسمك>-<الموضوع>`.
- Pull Request إلى `main` فقط، ولا أحد يكتب على `main` مباشرة.
- الإصدارات علامات (tags) على `main`: `v0.1.0`، `v0.2.0`، ...

التفاصيل في القسم 6 من [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md).

## التوثيق

الخطة الكاملة للمشروع (الفكرة، التقنيات، نموذج البيانات، تقسيم العمل، طريقة العمل على Git): [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md)

قواعد الكود والبنية: [CLAUDE.md](CLAUDE.md)

طبقة البيانات (من يستدعي ماذا، رفع التسجيلات، الـ Seed، اختبار القواعد): [docs/DATA_LAYER.md](docs/DATA_LAYER.md)

الحسابات والأدوار (من ينشئ ويغيّر ويوقف من، قواعد اسم المستخدم، نسيان كلمة السر): [docs/ACCOUNTS.md](docs/ACCOUNTS.md)

إنشاء أول مدير في المشروع الحقيقي: [docs/BOOTSTRAP_ADMIN.md](docs/BOOTSTRAP_ADMIN.md)
