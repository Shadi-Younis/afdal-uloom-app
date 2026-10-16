# أداة تحليل التسجيلات على الجهاز

تشغّل الأداة `tool/analyse_audio/analyse.mjs` تحليل السيرفر نفسه (`onRecordingUploaded`) على ملفات في جهازك، **بدون رفع أي شيء**. تستعمل كود الدوال نفسه (`functions/lib`)، فنتيجتها هي نتيجة السيرفر.

```powershell
# ملف واحد Stereo (الطالب يسار والشيخ يمين)
npm --prefix functions run analyse -- "C:\path\S014_002_001-020.mp3"

# ملفان (Export Stems من Studio One): صوت الطالب وصوت الشيخ
npm --prefix functions run analyse -- --student "C:\path\student.wav" --sheikh "C:\path\sheikh.wav"
```

يحتاج مرة واحدة `npm --prefix functions ci` (فيه ffmpeg). المسارات النسبية تُحسب من المجلد الذي شغّلت منه الأمر. إذا كان في اسم الملف أحرف عربية فقد لا يمرّ عبر npm في PowerShell؛ انسخه باسم لاتيني.

## ماذا تطبع

| السطر | المعنى |
|---|---|
| `Duration` | مدة الملف |
| `Mono` | `yes`: القناتان متشابهتان (لم يُصدَّر بقالب يسار/يمين)، فلا مواضع للشيخ |
| `Swapped` | `yes`: الشيخ كان في القناة اليسرى، فبدّل السيرفر القناتين تلقائياً |
| `bleedDb` | كم صوت الطالب في ميكروفون الشيخ مقارنة بميكروفونه (مع فرق الـ Gain)؛ عادة بين ‎-25 و‎-6 |
| `separationDb` | كم يعلو صوت الشيخ فوق ذلك؛ أقل من 10 يعني لا مواضع (الشيخ لم يتكلم، أو الميكروفونان لا يفصلان الصوتين) |
| `Segments` | كل موضع كلام للشيخ `mm:ss–mm:ss` كما سيظهر في التطبيق، وبين قوسين الثواني الدقيقة |

وفي وضع الملفين أيضاً:

| السطر | المعنى |
|---|---|
| `Length diff` | فرق المدة بين الملفين؛ أكثر من ثانية واحدة: السيرفر يرفض (`stems_length_mismatch`) |
| `Lag` | كم ملف الشيخ متأخر عن ملف الطالب (بالملّي ثانية)؛ أكثر من 100: السيرفر يرفض (`stems_misaligned`). يُقاس من صوت كل واحد في ميكروفون الآخر؛ إذا لم يوجد (Noise Gate) يطبع `unknown` ويقبل السيرفر الملفين |
| `Server` | ما سيفعله السيرفر: يدمج الملفين (الطالب يسار والشيخ يمين) ثم يحلل، أو يرفض ولماذا |

حتى إذا كان السيرفر سيرفض، تدمج الأداة الملفين وتحللهما للمعلومة فقط.

مثال على ملفات الاختبار (`tool/test_audio`):

```
Student:      C:\dev\test-audio\fixtures\stems_student.mp3 (60.97 s)
Sheikh:       C:\dev\test-audio\fixtures\stems_sheikh.mp3 (60.97 s)
Length diff:  0.00 s (max 1 s)
Lag:          0 ms, sheikh vs student (max ±100 ms; correlation 0.866)
Server:       joins the stems (student LEFT, sheikh RIGHT), then analyses:

Duration:     01:01 (60.97 s)
Mono:         no
Swapped:      no
bleedDb:      -15.0
separationDb: 30.0
Segments:     2
  00:13–00:18   (13.75 s – 18.00 s)
  00:33–00:39   (33.70 s – 39.00 s)
```

الأرقام التي يعتمد عليها التحليل كلها في `ANALYSIS` داخل `functions/src/lib/voice_analysis.ts`.
