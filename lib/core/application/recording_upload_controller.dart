import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/audio_formats.dart';
import '../constants/storage_paths.dart';
import '../constants/surahs.dart';
import '../errors/app_exception.dart';
import '../models/recording.dart';
import '../models/recording_type.dart';
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';
import '../repositories/recording_repository.dart';
import '../services/audio_upload.dart';
import 'recording_upload_request.dart';
import 'recording_upload_state.dart';
import 'recording_upload_status.dart';
import 'session_providers.dart';

/// Uploads ONE recording, for the teacher's studio upload and the
/// student's practice alike. The agreed flow (docs/DATA_LAYER.md):
/// new id -> storagePath -> create the document -> upload the file with
/// progress; when the upload fails or is cancelled the document is deleted
/// again, so no recording points at a missing file. (If even that delete
/// fails, cleanupStalledUploads removes the document after 24 h.)
class RecordingUploadController extends Notifier<RecordingUploadState> {
  AudioUpload? _upload;
  var _cancelRequested = false;

  @override
  RecordingUploadState build() {
    // Leaving the screen stops the upload; start() then deletes the
    // document.
    ref.onDispose(() => _upload?.cancel());
    return const RecordingUploadState();
  }

  /// The new recording's id once stored, or null when it was refused,
  /// failed or was cancelled (the reason is in the state). Ignored while an
  /// upload runs.
  Future<String?> start(RecordingUploadRequest request) async {
    if (state.isUploading) return null;
    final uploaderId = ref.read(sessionProvider).value?.uid;
    final extension = request.fileExtension.toLowerCase();
    final contentType = AudioFormats.contentTypeFor(extension);
    final refusal = _refusal(request, uploaderId, contentType);
    if (refusal != null) {
      state = RecordingUploadState(
        status: RecordingUploadStatus.failed,
        error: AppException(refusal),
      );
      return null;
    }

    final recordings = ref.read(recordingRepositoryProvider);
    final storage = ref.read(audioStorageServiceProvider);
    _cancelRequested = false;
    state = const RecordingUploadState(status: RecordingUploadStatus.uploading);

    final id = recordings.newId();
    final storagePath = StoragePaths.recording(
      request.studentId,
      id,
      extension: extension,
    );
    var created = false;
    try {
      await recordings.create(
        _recording(request, id, uploaderId!, storagePath),
      );
      created = true;
      if (_cancelRequested) {
        throw const AppException(AppErrorCode.uploadCancelled);
      }
      final upload = _upload = storage.upload(
        storagePath: storagePath,
        source: request.source,
        contentType: contentType!,
        onProgress: _onProgress,
      );
      await upload.done;
      _upload = null;
      if (ref.mounted) {
        state = RecordingUploadState(
          status: RecordingUploadStatus.done,
          progress: 1,
          recordingId: id,
        );
      }
      return id;
    } catch (error, stackTrace) {
      _upload = null;
      final failure = AppException.wrap(error, stackTrace);
      if (created) await _deleteQuietly(recordings, id);
      if (ref.mounted) {
        state = failure.code == AppErrorCode.uploadCancelled
            ? const RecordingUploadState(
                status: RecordingUploadStatus.cancelled,
              )
            : RecordingUploadState(
                status: RecordingUploadStatus.failed,
                error: failure,
              );
      }
      return null;
    }
  }

  /// Stops the running upload, if any; start() then deletes the document
  /// and the state becomes [RecordingUploadStatus.cancelled].
  Future<void> cancel() async {
    if (!state.isUploading) return;
    _cancelRequested = true;
    await _upload?.cancel();
  }

  /// Back to idle after a finished, failed or cancelled upload.
  void reset() {
    if (!state.isUploading) state = const RecordingUploadState();
  }

  /// Why [request] cannot even start, checked before anything is written.
  static AppErrorCode? _refusal(
    RecordingUploadRequest request,
    String? uploaderId,
    String? contentType,
  ) {
    if (uploaderId == null) return AppErrorCode.permissionDenied;
    if (contentType == null) return AppErrorCode.unsupportedFile;
    if (!isValidAyahRange(
      request.surahNumber,
      request.ayahFrom,
      request.ayahTo,
    )) {
      return AppErrorCode.invalidData;
    }
    return null;
  }

  void _onProgress(double progress) {
    if (ref.mounted && state.isUploading) {
      state = RecordingUploadState(
        status: RecordingUploadStatus.uploading,
        progress: progress.clamp(0, 1),
      );
    }
  }

  static Recording _recording(
    RecordingUploadRequest request,
    String id,
    String uploaderId,
    String storagePath,
  ) => Recording(
    id: id,
    studentId: request.studentId,
    halaqaId: request.halaqaId,
    teacherId: request.teacherId,
    uploadedBy: uploaderId,
    type: request.type,
    surahNumber: request.surahNumber,
    ayahFrom: request.ayahFrom,
    ayahTo: request.ayahTo,
    storagePath: storagePath,
    durationSec: request.durationSec,
    recordedAt: request.recordedAt,
    // Ignored: the repository sets the server time.
    createdAt: request.recordedAt,
    unreadFeedback: false,
    // A studio recording is reviewed by definition; practice waits for the
    // teacher (firestore.rules requires both).
    reviewed: request.type == RecordingType.official,
  );

  static Future<void> _deleteQuietly(
    RecordingRepository recordings,
    String id,
  ) async {
    try {
      await recordings.delete(id);
    } on Object {
      // The upload's own error is what the user needs to see; the daily
      // cleanup deletes this document.
    }
  }
}

final recordingUploadControllerProvider =
    NotifierProvider.autoDispose<
      RecordingUploadController,
      RecordingUploadState
    >(RecordingUploadController.new);
