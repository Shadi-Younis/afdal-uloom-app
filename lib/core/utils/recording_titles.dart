import '../constants/app_strings.dart';
import '../constants/surahs.dart';
import '../models/recording.dart';
import 'date_format.dart';

// Surah and ayat of an official recording are optional: every place that
// shows a recording names it through these, so one without them never
// shows an empty or broken title.

/// The title of [recording] in a list: "البقرة: الآيات ١–٢٠", "سورة البقرة"
/// without ayat, «تسجيل ١٦ أكتوبر ٢٠٢٦» (its recorded day) without a surah.
String recordingTitleOf(Recording recording) =>
    switch ((recording.surahNumber, recording.ayahFrom, recording.ayahTo)) {
      (final surah?, final from?, final to?) => formatRecordingTitle(
        surah,
        from,
        to,
      ),
      _ => recordingHeadingOf(recording),
    };

/// The name of [recording] on its own (a cartouche): "سورة البقرة", or
/// «تسجيل ١٦ أكتوبر ٢٠٢٦» without a surah.
String recordingHeadingOf(Recording recording) =>
    switch (recording.surahNumber) {
      final surah? => AppStrings.surahName(surahByNumber(surah).nameAr),
      null => AppStrings.untitledRecording(formatDay(recording.recordedAt)),
    };

/// Its ayat, "الآيات ١–٢٠" or "الآية ٥"; null when it has none.
String? recordingAyatOf(Recording recording) =>
    switch ((recording.ayahFrom, recording.ayahTo)) {
      (final from?, final to?) => formatAyahRange(from, to),
      _ => null,
    };
