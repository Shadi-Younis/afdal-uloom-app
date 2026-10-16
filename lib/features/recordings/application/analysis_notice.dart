import '../../../core/constants/analysis_errors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/models/analysis_status.dart';
import '../../../core/models/recording.dart';
import '../../../core/models/recording_source.dart';
import '../../../core/models/recording_type.dart';

/// What the recording screen says about the server's analysis.
enum AnalysisNotice {
  /// «جاري تحليل التسجيل…»
  pending,

  /// The file has no separate sheikh channel.
  mono,

  /// The analysis failed.
  failed,

  /// A two-file recording: waiting for its files, or joining them
  /// («جارٍ دمج الملفين…»). Its teacher only.
  merging,

  /// The two files could not be joined: their lengths differ. Its teacher
  /// only.
  stemsLengthMismatch,

  /// The two files could not be joined: they do not line up. Its teacher
  /// only.
  stemsMisaligned,

  /// The two files could not be joined (another reason). Its teacher only.
  stemsFailed,
}

/// The notice for [recording] at [now], or null when there is nothing to
/// say: practice recordings are never analysed, a finished analysis shows
/// its markers, and an official recording without any analysis that is
/// older than AppDurations.analysisPendingWindow was uploaded before the
/// analysis existed.
///
/// A two-file recording before its files are joined tells [canManage] (its
/// teacher and admins) why it cannot be played yet; its student, for whom
/// nothing changed, only sees that it is being analysed or failed.
AnalysisNotice? analysisNoticeFor(
  Recording recording,
  DateTime now, {
  bool canManage = true,
}) {
  if (recording.type != RecordingType.official) return null;
  final analysis = recording.analysis;
  if (recording.source == RecordingSource.stems && !recording.hasAudio) {
    if (analysis == null || analysis.status == AnalysisStatus.merging) {
      return canManage ? AnalysisNotice.merging : AnalysisNotice.pending;
    }
    if (!canManage) return AnalysisNotice.failed;
    return switch (analysis.error) {
      AnalysisErrors.stemsLengthMismatch => AnalysisNotice.stemsLengthMismatch,
      AnalysisErrors.stemsMisaligned => AnalysisNotice.stemsMisaligned,
      _ => AnalysisNotice.stemsFailed,
    };
  }
  return switch (analysis?.status) {
    AnalysisStatus.merging || AnalysisStatus.pending => AnalysisNotice.pending,
    AnalysisStatus.mono => AnalysisNotice.mono,
    AnalysisStatus.failed => AnalysisNotice.failed,
    AnalysisStatus.done => null,
    null =>
      now.difference(recording.createdAt) < AppDurations.analysisPendingWindow
          ? AnalysisNotice.pending
          : null,
  };
}
