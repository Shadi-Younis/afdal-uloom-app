import '../../../core/constants/app_durations.dart';
import '../../../core/models/analysis_status.dart';
import '../../../core/models/recording.dart';
import '../../../core/models/recording_type.dart';

/// What the recording screen says about the server's analysis.
enum AnalysisNotice {
  /// «جاري تحليل التسجيل…»
  pending,

  /// The file has no separate sheikh channel.
  mono,

  /// The analysis failed.
  failed,
}

/// The notice for [recording] at [now], or null when there is nothing to
/// say: practice recordings are never analysed, a finished analysis shows
/// its markers, and an official recording without any analysis that is
/// older than AppDurations.analysisPendingWindow was uploaded before the
/// analysis existed.
AnalysisNotice? analysisNoticeFor(Recording recording, DateTime now) {
  if (recording.type != RecordingType.official) return null;
  return switch (recording.analysis?.status) {
    AnalysisStatus.pending => AnalysisNotice.pending,
    AnalysisStatus.mono => AnalysisNotice.mono,
    AnalysisStatus.failed => AnalysisNotice.failed,
    AnalysisStatus.done => null,
    null =>
      now.difference(recording.createdAt) < AppDurations.analysisPendingWindow
          ? AnalysisNotice.pending
          : null,
  };
}
