import '../errors/app_exception.dart';
import 'recording_upload_status.dart';

/// The state of RecordingUploadController.
class RecordingUploadState {
  const RecordingUploadState({
    this.status = RecordingUploadStatus.idle,
    this.progress = 0,
    this.stemProgress,
    this.recordingId,
    this.error,
  });

  final RecordingUploadStatus status;

  /// 0..1 while uploading; 1 when done. Both files together for a
  /// two-file recording.
  final double progress;

  /// A two-file recording while uploading: each file's own 0..1.
  final StemProgress? stemProgress;

  /// The new recording, once [RecordingUploadStatus.done].
  final String? recordingId;

  /// Why it [RecordingUploadStatus.failed].
  final AppException? error;

  bool get isUploading => status == RecordingUploadStatus.uploading;

  @override
  bool operator ==(Object other) =>
      other is RecordingUploadState &&
      other.status == status &&
      other.progress == progress &&
      other.stemProgress == stemProgress &&
      other.recordingId == recordingId &&
      other.error?.code == error?.code;

  @override
  int get hashCode =>
      Object.hash(status, progress, stemProgress, recordingId, error?.code);

  @override
  String toString() =>
      'RecordingUploadState(${status.name}, progress: $progress, '
      'stemProgress: $stemProgress, recordingId: $recordingId, '
      'error: ${error?.code.name})';
}

/// How far each file of a two-file upload is, 0..1.
typedef StemProgress = ({double student, double sheikh});
