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

اختبار سريع للربط مع الـ Emulators (يعمل فقط مع `USE_EMULATORS=true`):

```bash
flutter test integration_test/emulator_smoke_test.dart -d <device-id> --dart-define=USE_EMULATORS=true --dart-define=EMULATOR_HOST=<LAN IP>
```

## التوثيق

الخطة الكاملة للمشروع (الفكرة، التقنيات، نموذج البيانات، تقسيم العمل، طريقة العمل على Git): [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md)
