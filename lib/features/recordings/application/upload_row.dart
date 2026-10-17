import 'package:flutter/foundation.dart' show ValueGetter;

import '../../../core/application/recording_upload_state.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/picked_audio_file.dart';
import '../../../core/models/recording_source.dart';
import '../../../core/models/stem_role.dart';
import '../../../core/utils/audio_file_check.dart';
import '../../../core/utils/ayat_problem.dart';
import 'upload_row_status.dart';

/// One recording of the upload page: its file (or, in two-file mode, the
/// student's and the sheikh's), what it is a recording of, and how its
/// upload goes. The type is always official (a studio recording).
class UploadRow {
  const UploadRow({
    required this.key,
    required this.file,
    required this.recordedAt,
    this.studentId,
    this.surahNumber,
    this.ayahFrom,
    this.ayahTo,
    this.fileProblem,
    this.source = RecordingSource.stereo,
    this.studentFile,
    this.sheikhFile,
    this.studentDuration,
    this.sheikhDuration,
    this.status = UploadRowStatus.editing,
    this.progress = 0,
    this.stemProgress,
    this.error,
    this.recordingId,
  });

  /// Unique on the page; also the key of its RecordingUploadController.
  final String key;

  /// The file the row was made from: what one-file mode uploads.
  final PickedAudioFile file;
  final String? studentId;
  final int? surahNumber;
  final int? ayahFrom;
  final int? ayahTo;
  final DateTime recordedAt;

  /// Why [file] itself can never be uploaded
  /// ([AppErrorCode.unsupportedFile] or [AppErrorCode.fileTooLarge]).
  final AppErrorCode? fileProblem;

  /// «ملف واحد (يسار/يمين)» or «ملفين: الطالب + الشيخ».
  final RecordingSource source;

  /// Two-file mode: each microphone's file, and its length when its
  /// headers tell (null: unknown, or not read yet).
  final PickedAudioFile? studentFile;
  final PickedAudioFile? sheikhFile;
  final Duration? studentDuration;
  final Duration? sheikhDuration;
  final UploadRowStatus status;

  /// 0..1 while uploading.
  final double progress;

  /// Two-file mode while uploading: each file's own 0..1.
  final StemProgress? stemProgress;

  /// Why the last upload failed.
  final AppException? error;

  /// The new recording, once [UploadRowStatus.done].
  final String? recordingId;

  bool get isStems => source == RecordingSource.stems;

  PickedAudioFile? stemFile(StemRole role) =>
      role == StemRole.student ? studentFile : sheikhFile;

  Duration? stemDuration(StemRole role) =>
      role == StemRole.student ? studentDuration : sheikhDuration;

  /// Both files of two-file mode are there.
  bool get hasBothStems => studentFile != null && sheikhFile != null;

  /// Why the two files cannot be uploaded: one cannot be uploaded at all,
  /// or their lengths differ by more than
  /// AppDurations.stemsMaxLengthDifference (checked when both are known).
  AppErrorCode? get stemsProblem {
    for (final file in [studentFile, sheikhFile]) {
      if (file == null) continue;
      if (uploadProblemOf(file) case final problem?) return problem;
    }
    final (student, sheikh) = (studentDuration, sheikhDuration);
    if (student != null &&
        sheikh != null &&
        (student - sheikh).abs() > AppDurations.stemsMaxLengthDifference) {
      return AppErrorCode.stemsLengthMismatch;
    }
    return null;
  }

  /// What is wrong with the surah and ayat (shown under the ayat); null
  /// when they may be uploaded. All three may stay empty, or the ayat
  /// alone.
  AyatProblem? get ayatProblem => ayatProblemOf(surahNumber, ayahFrom, ayahTo);

  /// The student is chosen, surah and ayat are allowed (they are optional)
  /// and the file (or both files) can be uploaded.
  bool get isComplete =>
      fileProblem == null &&
      studentId != null &&
      ayatProblem == null &&
      (!isStems || (hasBothStems && stemsProblem == null));

  /// «رفع الكل» (or retry) may start it.
  bool get canStart => isComplete && status.isEditable;

  /// Nullable fields take a getter, so they can be cleared to null.
  UploadRow copyWith({
    ValueGetter<String?>? studentId,
    ValueGetter<int?>? surahNumber,
    ValueGetter<int?>? ayahFrom,
    ValueGetter<int?>? ayahTo,
    DateTime? recordedAt,
    RecordingSource? source,
    ValueGetter<PickedAudioFile?>? studentFile,
    ValueGetter<PickedAudioFile?>? sheikhFile,
    ValueGetter<Duration?>? studentDuration,
    ValueGetter<Duration?>? sheikhDuration,
    UploadRowStatus? status,
    double? progress,
    ValueGetter<StemProgress?>? stemProgress,
    ValueGetter<AppException?>? error,
    ValueGetter<String?>? recordingId,
  }) => UploadRow(
    key: key,
    file: file,
    fileProblem: fileProblem,
    studentId: studentId != null ? studentId() : this.studentId,
    surahNumber: surahNumber != null ? surahNumber() : this.surahNumber,
    ayahFrom: ayahFrom != null ? ayahFrom() : this.ayahFrom,
    ayahTo: ayahTo != null ? ayahTo() : this.ayahTo,
    recordedAt: recordedAt ?? this.recordedAt,
    source: source ?? this.source,
    studentFile: studentFile != null ? studentFile() : this.studentFile,
    sheikhFile: sheikhFile != null ? sheikhFile() : this.sheikhFile,
    studentDuration: studentDuration != null
        ? studentDuration()
        : this.studentDuration,
    sheikhDuration: sheikhDuration != null
        ? sheikhDuration()
        : this.sheikhDuration,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    stemProgress: stemProgress != null ? stemProgress() : this.stemProgress,
    error: error != null ? error() : this.error,
    recordingId: recordingId != null ? recordingId() : this.recordingId,
  );

  /// [file] (and its [duration]) in the [role] slot of two-file mode.
  UploadRow withStem(
    StemRole role,
    PickedAudioFile? file,
    Duration? duration,
  ) => role == StemRole.student
      ? copyWith(studentFile: () => file, studentDuration: () => duration)
      : copyWith(sheikhFile: () => file, sheikhDuration: () => duration);

  @override
  String toString() =>
      'UploadRow($key, ${file.name}, ${source.value}, '
      'stems: ${studentFile?.name} / ${sheikhFile?.name}, '
      'student: $studentId, surah: $surahNumber $ayahFrom-$ayahTo, '
      '${status.name}, progress: $progress, error: ${error?.code.name})';
}
