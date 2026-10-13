/// Reading the student, surah and ayat from the name of a file exported
/// from the studio (docs/PROJECT_PLAN.md section 3).
library;

import '../constants/model_limits.dart';
import '../constants/surahs.dart';
import 'parsed_recording_name.dart';

final _code = RegExp(ModelLimits.studentCodePattern, caseSensitive: false);
final _date = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
final _surah = RegExp(r'^\d{1,3}$');
// Anything after the ayat that does not start with a digit or a dash is
// ignored: a stem's track name, `001-020 - Student`.
final _ayat = RegExp(r'^(\d{1,3})(?:-(\d{1,3}))?(?:[^\d-].*)?$');

/// The parts of [fileName] in the studio naming
/// `{studentCode}_[{yyyy-mm-dd}_]{surah}_{fromAyah}-{toAyah}.{ext}`:
/// `S014_002_001-020.mp3`, `S014_2_1-20.wav` or
/// `S023_2026-10-05_002_1-20.mp3`; one ayah may be written alone
/// (`S014_067_5`). A stem's track name may follow
/// (`S014_002_001-020 - Student.wav`, `S014_002_001-020_sheikh.wav`). Whatever does not parse, or does not exist in the
/// Quran (surah 115, ayat past the surah's end), is left null; the code is
/// not checked against any student here.
ParsedRecordingName parseRecordingFileName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final base = (dot > 0 ? fileName.substring(0, dot) : fileName).trim();
  final parts = base.split('_');
  var i = 0;

  String? code;
  if (i < parts.length && _code.hasMatch(parts[i])) {
    code = parts[i++].toUpperCase();
  }

  DateTime? day;
  if (i < parts.length) {
    if (_date.firstMatch(parts[i]) case final m?) {
      day = _validDate(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
      i++;
    }
  }

  int? surah;
  if (i < parts.length && _surah.hasMatch(parts[i])) {
    final number = int.parse(parts[i++]);
    if (number >= ModelLimits.surahMin && number <= ModelLimits.surahMax) {
      surah = number;
    }
  }

  int? from, to;
  if (surah != null && i < parts.length) {
    if (_ayat.firstMatch(parts[i]) case final m?) {
      final a = int.parse(m[1]!);
      final b = m[2] == null ? a : int.parse(m[2]!);
      if (isValidAyahRange(surah, a, b)) (from, to) = (a, b);
    }
  }

  return ParsedRecordingName(
    studentCode: code,
    surahNumber: surah,
    ayahFrom: from,
    ayahTo: to,
    recordedAt: day,
  );
}

/// The day, or null for one that does not exist (2026-02-30).
DateTime? _validDate(int year, int month, int day) {
  final date = DateTime(year, month, day);
  return date.year == year && date.month == month && date.day == day
      ? date
      : null;
}
