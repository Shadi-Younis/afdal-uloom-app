/// Pure helpers of the upload page's two-file mode: where dropped or picked
/// files go, and what their names fill in.
library;

import '../../../core/application/my_students_providers.dart';
import '../../../core/models/picked_audio_file.dart';
import '../../../core/models/stem_role.dart';
import '../../../core/utils/recording_file_name.dart';
import '../../../core/utils/stem_role_of_name.dart';
import 'upload_row.dart';

/// Where [files] go in [row]'s two slots. Two (or more: the rest is
/// ignored) fill both: by the words in their names (stemRoleOfName),
/// otherwise in the order dropped, student first. One goes to [into] (the
/// zone it was dropped on or picked for), else where its name says, else
/// the first empty slot, else the student's.
List<(StemRole, PickedAudioFile)> placeStems(
  UploadRow row,
  List<PickedAudioFile> files, {
  StemRole? into,
}) {
  if (files.isEmpty) return const [];
  if (files.length == 1) {
    final file = files.single;
    final empty = row.studentFile == null
        ? StemRole.student
        : row.sheikhFile == null
        ? StemRole.sheikh
        : null;
    return [
      (into ?? stemRoleOfName(file.name) ?? empty ?? StemRole.student, file),
    ];
  }
  final [first, second, ...] = files;
  final firstRole =
      stemRoleOfName(first.name) ??
      stemRoleOfName(second.name)?.other ??
      StemRole.student;
  return [(firstRole, first), (firstRole.other, second)];
}

/// [row] with what the names of [files] say (parseRecordingFileName) filled
/// in where it is still empty: the student (by code, among [students]),
/// the surah and ayat, and the day when the row still has [today]. The
/// first file that says something wins.
UploadRow prefilledFrom(
  UploadRow row,
  List<PickedAudioFile> files,
  List<StudentInHalaqa> students,
  DateTime today,
) {
  var next = row;
  for (final file in files) {
    final parsed = parseRecordingFileName(file.name);
    final code = parsed.studentCode;
    final student = code == null
        ? null
        : students.where((s) => s.student.studentCode == code).firstOrNull;
    if (next.studentId == null && student != null) {
      next = next.copyWith(studentId: () => student.student.id);
    }
    if (next.surahNumber == null && parsed.surahNumber != null) {
      next = next.copyWith(
        surahNumber: () => parsed.surahNumber,
        ayahFrom: () => parsed.ayahFrom,
        ayahTo: () => parsed.ayahTo,
      );
    } else if (next.surahNumber == parsed.surahNumber &&
        next.ayahFrom == null &&
        next.ayahTo == null) {
      next = next.copyWith(
        ayahFrom: () => parsed.ayahFrom,
        ayahTo: () => parsed.ayahTo,
      );
    }
    final day = parsed.recordedAt;
    if (day != null && _sameDay(next.recordedAt, today)) {
      next = next.copyWith(recordedAt: day);
    }
  }
  return next;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
