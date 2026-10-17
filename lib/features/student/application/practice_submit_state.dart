import 'package:flutter/foundation.dart' show ValueGetter;

import '../../../core/constants/surahs.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/picked_audio_file.dart';

/// What the practice is of (surah and ayat), the file picked instead of
/// recording, and why sending was refused before it started.
class PracticeSubmitState {
  const PracticeSubmitState({
    this.surahNumber,
    this.ayahFrom,
    this.ayahTo,
    this.file,
    this.fileProblem,
    this.showAyatProblem = false,
    this.error,
  });

  final int? surahNumber;
  final int? ayahFrom;
  final int? ayahTo;

  /// «اختيار ملف»: an audio file to send instead of a take.
  final PickedAudioFile? file;

  /// Why [file] cannot be sent (type, size).
  final AppErrorCode? fileProblem;

  /// «حفظ» was pressed without valid ayat.
  final bool showAyatProblem;

  /// Sending could not even start (e.g. the student has no halaqa).
  final AppException? error;

  /// Surah and ayat are given and exist.
  bool get hasValidAyat => switch ((surahNumber, ayahFrom, ayahTo)) {
    (final s?, final from?, final to?) => isValidAyahRange(s, from, to),
    _ => false,
  };

  /// Ayat are given but not in the surah (shown under the fields).
  bool get hasInvalidAyat =>
      surahNumber != null &&
      ayahFrom != null &&
      ayahTo != null &&
      !hasValidAyat;

  /// Nullable fields take a getter, so they can be cleared to null. The
  /// refusal shown ([showAyatProblem], [error]) goes with every change.
  PracticeSubmitState copyWith({
    ValueGetter<int?>? surahNumber,
    ValueGetter<int?>? ayahFrom,
    ValueGetter<int?>? ayahTo,
    ValueGetter<PickedAudioFile?>? file,
    ValueGetter<AppErrorCode?>? fileProblem,
    bool showAyatProblem = false,
    AppException? error,
  }) => PracticeSubmitState(
    surahNumber: surahNumber != null ? surahNumber() : this.surahNumber,
    ayahFrom: ayahFrom != null ? ayahFrom() : this.ayahFrom,
    ayahTo: ayahTo != null ? ayahTo() : this.ayahTo,
    file: file != null ? file() : this.file,
    fileProblem: fileProblem != null ? fileProblem() : this.fileProblem,
    showAyatProblem: showAyatProblem,
    error: error,
  );

  @override
  String toString() =>
      'PracticeSubmitState(surah: $surahNumber $ayahFrom-$ayahTo, '
      'file: $file, fileProblem: ${fileProblem?.name}, '
      'showAyatProblem: $showAyatProblem, error: ${error?.code.name})';
}
