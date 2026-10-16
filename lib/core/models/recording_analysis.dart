import '../constants/analysis_errors.dart';
import '../constants/firestore_paths.dart';
import '../utils/map_reader.dart';
import 'analysis_status.dart';

/// The server's analysis of an official recording
/// (`recordings/{id}.analysis`), written only by onRecordingUploaded.
class RecordingAnalysis {
  /// Throws [ArgumentError] for a negative [segmentCount].
  ///
  /// Not const: a const constructor cannot run this check.
  RecordingAnalysis({
    required this.status,
    this.segmentCount,
    this.error,
    this.swapped,
    this.bleedDb,
    this.separationDb,
    this.stemsLagMs,
    this.unknownStatus,
  }) {
    final count = segmentCount;
    if (count != null && count < 0) {
      throw ArgumentError.value(count, 'segmentCount', 'must be >= 0');
    }
  }

  /// Throws [FormatException] for a missing status or a wrong type. A
  /// status this app does not know reads as [AnalysisStatus.pending], kept
  /// as [unknownStatus].
  factory RecordingAnalysis.fromMap(Map<String, dynamic> map) {
    final raw = readRequired<String>(map, Fields.analysisStatus);
    final status = AnalysisStatus.fromValue(raw);
    return RecordingAnalysis(
      status: status,
      unknownStatus: status.value == raw ? null : raw,
      segmentCount: readOptional<int>(map, Fields.segmentCount),
      error: readOptional<String>(map, Fields.analysisError),
      swapped: readOptional<bool>(map, Fields.swapped),
      // Firestore keeps -15.0 written by the server as the integer -15.
      bleedDb: readOptional<num>(map, Fields.bleedDb)?.toDouble(),
      separationDb: readOptional<num>(map, Fields.separationDb)?.toDouble(),
      stemsLagMs: readOptional<int>(map, Fields.stemsLagMs),
    );
  }

  final AnalysisStatus status;

  /// How many voice markers were made ([AnalysisStatus.done] only).
  final int? segmentCount;

  /// A short code when [AnalysisStatus.failed]; see AnalysisErrors.
  final String? error;

  /// The sheikh was on the LEFT and the server swapped the channels
  /// ([AnalysisStatus.done] only).
  final bool? swapped;

  /// How loud the student is in the sheikh's microphone relative to his
  /// own, in dB ([AnalysisStatus.done] only; for the logs).
  final double? bleedDb;

  /// How far the sheikh's voice stands above that, in dB
  /// ([AnalysisStatus.done] only; for the logs).
  final double? separationDb;

  /// A two-file recording: how late the sheikh's file was, in ms.
  final int? stemsLagMs;

  /// The status as stored when this app does not know it (a newer
  /// server's); [status] is then [AnalysisStatus.pending]. For the logs.
  final String? unknownStatus;

  /// The server could not join the two files of a two-file recording.
  bool get isStemsFailure =>
      status == AnalysisStatus.failed &&
      (error?.startsWith(AnalysisErrors.stemsPrefix) ?? false);

  Map<String, dynamic> toMap() => {
    Fields.analysisStatus: unknownStatus ?? status.value,
    Fields.segmentCount: ?segmentCount,
    Fields.analysisError: ?error,
    Fields.swapped: ?swapped,
    Fields.bleedDb: ?bleedDb,
    Fields.separationDb: ?separationDb,
    Fields.stemsLagMs: ?stemsLagMs,
  };

  @override
  bool operator ==(Object other) =>
      other is RecordingAnalysis &&
      other.status == status &&
      other.segmentCount == segmentCount &&
      other.error == error &&
      other.swapped == swapped &&
      other.bleedDb == bleedDb &&
      other.separationDb == separationDb &&
      other.stemsLagMs == stemsLagMs &&
      other.unknownStatus == unknownStatus;

  @override
  int get hashCode => Object.hash(
    status,
    segmentCount,
    error,
    swapped,
    bleedDb,
    separationDb,
    stemsLagMs,
    unknownStatus,
  );

  @override
  String toString() =>
      'RecordingAnalysis(${status.value}, segmentCount: $segmentCount, '
      'error: $error, swapped: $swapped, bleedDb: $bleedDb, '
      'separationDb: $separationDb, stemsLagMs: $stemsLagMs, '
      'unknownStatus: $unknownStatus)';
}
