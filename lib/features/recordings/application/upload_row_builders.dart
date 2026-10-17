/// Building the upload page's rows and their upload requests, apart from
/// UploadBatchController so it stays short.
library;

import '../../../core/application/my_students_providers.dart';
import '../../../core/application/recording_upload_request.dart';
import '../../../core/models/picked_audio_file.dart';
import '../../../core/models/recording_type.dart';
import '../../../core/utils/audio_file_check.dart';
import '../../../core/utils/recording_file_name.dart';
import 'upload_row.dart';

/// A new row [key] for [file], with what its name says
/// (parseRecordingFileName) filled in. A code that is not one of
/// [students] leaves the student empty; a name without a code gets
/// [defaultStudentId] (when it is one of them). A file that cannot be
/// uploaded (type, size) gets a row that shows why.
UploadRow newUploadRow({
  required String key,
  required PickedAudioFile file,
  required List<StudentInHalaqa> students,
  required String? defaultStudentId,
  required DateTime today,
}) {
  final parsed = parseRecordingFileName(file.name);
  final code = parsed.studentCode;
  final byCode = code == null
      ? null
      : students.where((s) => s.student.studentCode == code).firstOrNull;
  final fallback = students
      .where((s) => s.student.id == defaultStudentId)
      .firstOrNull;
  return UploadRow(
    key: key,
    file: file,
    fileProblem: uploadProblemOf(file),
    studentId: code == null ? fallback?.student.id : byCode?.student.id,
    surahNumber: parsed.surahNumber,
    ayahFrom: parsed.ayahFrom,
    ayahTo: parsed.ayahTo,
    recordedAt: parsed.recordedAt ?? today,
  );
}

/// The official recording [row] uploads, for [student] (its halaqa and
/// teacher go along: firestore.rules check them). Opens the file, or both
/// files in two-file mode (the student's as the request's file). [row]
/// must be complete (UploadRow.isComplete).
Future<RecordingUploadRequest> uploadRequestOf(
  UploadRow row,
  StudentInHalaqa student,
) async {
  final file = row.isStems ? row.studentFile! : row.file;
  final sheikh = row.isStems ? row.sheikhFile : null;
  return RecordingUploadRequest(
    studentId: student.student.id,
    halaqaId: student.halaqa.id,
    teacherId: student.halaqa.teacherId,
    type: RecordingType.official,
    surahNumber: row.surahNumber,
    ayahFrom: row.ayahFrom,
    ayahTo: row.ayahTo,
    recordedAt: row.recordedAt,
    source: await file.open(),
    fileExtension: file.extension,
    sheikhSource: await sheikh?.open(),
    sheikhFileExtension: sheikh?.extension,
  );
}
