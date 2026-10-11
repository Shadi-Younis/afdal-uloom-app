import '../constants/firestore_paths.dart';
import '../utils/map_reader.dart';
import 'analysis_status.dart';

/// The server's analysis of an official recording
/// (`recordings/{id}.analysis`), written only by onRecordingUploaded.
class RecordingAnalysis {
  /// Throws [ArgumentError] for a negative [segmentCount].
  ///
  /// Not const: a const constructor cannot run this check.
  RecordingAnalysis({required this.status, this.segmentCount, this.error}) {
    final count = segmentCount;
    if (count != null && count < 0) {
      throw ArgumentError.value(count, 'segmentCount', 'must be >= 0');
    }
  }

  /// Throws [FormatException] for a missing status, a wrong type or an
  /// unknown status.
  factory RecordingAnalysis.fromMap(Map<String, dynamic> map) =>
      RecordingAnalysis(
        status: AnalysisStatus.fromValue(
          readRequired<String>(map, Fields.analysisStatus),
        ),
        segmentCount: readOptional<int>(map, Fields.segmentCount),
        error: readOptional<String>(map, Fields.analysisError),
      );

  final AnalysisStatus status;

  /// How many voice markers were made ([AnalysisStatus.done] only).
  final int? segmentCount;

  /// A short code for logs when [AnalysisStatus.failed]; never shown.
  final String? error;

  Map<String, dynamic> toMap() => {
    Fields.analysisStatus: status.value,
    Fields.segmentCount: ?segmentCount,
    Fields.analysisError: ?error,
  };

  @override
  bool operator ==(Object other) =>
      other is RecordingAnalysis &&
      other.status == status &&
      other.segmentCount == segmentCount &&
      other.error == error;

  @override
  int get hashCode => Object.hash(status, segmentCount, error);

  @override
  String toString() =>
      'RecordingAnalysis(${status.value}, segmentCount: $segmentCount, '
      'error: $error)';
}
