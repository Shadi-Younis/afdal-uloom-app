# بيانات تجريبية للـ Emulator

يملأ هذا السكربت الـ Emulators (Auth وFirestore وStorage) بحسابات وحلقات وتسجيلات وملاحظات. شغّله عبر `tool/seed_emulator.ps1` (انظر `docs/DATA_LAYER.md`).

## ملفات التلاوة

كل تسجيل في الـ Seed يشغّل تلاوة حقيقية للشيخ محمد صديق المنشاوي (مرتّل، رواية حفص): الفاتحة، والإخلاص، والفلق، والناس من [mp3quran.net](https://mp3quran.net)، والآيات ١–٥ من سورة الملك (ملف لكل آية) من [everyayah.com](https://everyayah.com). القائمة الكاملة بالروابط والسور والآيات في `test_audio.json`، وسورة كل تسجيل وآياته تؤخذ من الملف الذي يشغّله.

الملفات (حوالي ٣٫٣ ميغابايت) **لا تُرفع إلى Git أبداً**، وتُحفظ خارج المستودع في `C:\dev\test-audio\minshawi\` (أي مجلد `test-audio\minshawi` بجانب مجلد المشروع). لتنزيلها أو إعادة تنزيلها:

```powershell
powershell -ExecutionPolicy Bypass -File tool/seed/download_test_audio.ps1          # ينزّل الناقص فقط
powershell -ExecutionPolicy Bypass -File tool/seed/download_test_audio.ps1 -Force   # يعيد تنزيل الكل
```

تسجيلات الاستوديو `rec-26` (ملف Stereo) و`rec-28` (ملفان: الطالب والشيخ) و`rec-29` (قناتان مبدّلتان) تُبنى من هذه الملفات (`tool/test_audio/build_fixtures.mjs`) في `C:\dev\test-audio\fixtures\` عند أول تشغيل للـ Seed إذا لم تكن موجودة. وكذلك تسجيلات التدريب: كل واحد منها هو ملف التلاوة نفسه بقناة واحدة (Mono) بصيغة `m4a` كما يسجّلها هاتف الطالب (`practice_*.m4a` في نفس المجلد).

لاستخدام مجلد آخر عرّف `SEED_AUDIO_DIR` قبل التنزيل وقبل الـ Seed. إذا كان المجلد أو أحد الملفات ناقصاً يرفض الـ Seed العمل ويذكر هذا الأمر.

التسجيل `rec-30` (الطالب `s001`) مرفوع بلا سورة ولا آيات (اختيارية منذ المهمة 12)، فيظهر باسم «تسجيل» وتاريخه.

هذه الملفات للـ Emulators المحلية فقط، ولا تُرفع إلى المشروع الحقيقي أبداً.
