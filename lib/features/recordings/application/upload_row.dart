import 'package:flutter/foundation.dart' show ValueGetter;

import '../../../core/constants/surahs.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/picked_audio_file.dart';
import 'upload_row_status.dart';

/// One file of the upload page: the file, what it is a recording of, and
/// how its upload goes. The type is always official (a studio recording).
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
    this.status = UploadRowStatus.editing,
    this.progress = 0,
    this.error,
    this.recordingId,
  });

  /// Unique on the page; also the key of its RecordingUploadController.
  final String key;
  final PickedAudioFile file;
  final String? studentId;
  final int? surahNumber;
  final int? ayahFrom;
  final int? ayahTo;
  final DateTime recordedAt;

  /// Why the file itself can never be uploaded
  /// ([AppErrorCode.unsupportedFile] or [AppErrorCode.fileTooLarge]).
  final AppErrorCode? fileProblem;
  final UploadRowStatus status;

  /// 0..1 while uploading.
  final double progress;

  /// Why the last upload failed.
  final AppException? error;

  /// The new recording, once [UploadRowStatus.done].
  final String? recordingId;

  /// Surah and ayat are given and exist.
  bool get hasValidAyat => switch ((surahNumber, ayahFrom, ayahTo)) {
    (final s?, final from?, final to?) => isValidAyahRange(s, from, to),
    _ => false,
  };

  /// Ayat are given but not in the surah (shown as an error).
  bool get hasInvalidAyat =>
      surahNumber != null &&
      ayahFrom != null &&
      ayahTo != null &&
      !hasValidAyat;

  /// Every field is filled in and the file can be uploaded.
  bool get isComplete =>
      fileProblem == null && studentId != null && hasValidAyat;

  /// «رفع الكل» (or retry) may start it.
  bool get canStart => isComplete && status.isEditable;

  /// Nullable fields take a getter, so they can be cleared to null.
  UploadRow copyWith({
    ValueGetter<String?>? studentId,
    ValueGetter<int?>? surahNumber,
    ValueGetter<int?>? ayahFrom,
    ValueGetter<int?>? ayahTo,
    DateTime? recordedAt,
    UploadRowStatus? status,
    double? progress,
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
    status: status ?? this.status,
    progress: progress ?? this.progress,
    error: error != null ? error() : this.error,
    recordingId: recordingId != null ? recordingId() : this.recordingId,
  );

  @override
  String toString() =>
      'UploadRow($key, ${file.name}, student: $studentId, '
      'surah: $surahNumber $ayahFrom-$ayahTo, ${status.name}, '
      'progress: $progress, error: ${error?.code.name})';
}
