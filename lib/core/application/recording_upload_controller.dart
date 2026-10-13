import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/audio_formats.dart';
import '../constants/storage_paths.dart';
import '../constants/surahs.dart';
import '../errors/app_exception.dart';
import '../models/audio_source.dart';
import '../models/recording.dart';
import '../models/recording_source.dart';
import '../models/stem_paths.dart';
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
///
/// A two-file recording (RecordingUploadRequest.isStems) uploads its two
/// files side by side to its stemPaths instead; the server joins them into
/// its storagePath. If either fails, the other is stopped and the document
/// deleted.
///
/// One controller per upload key: the upload page runs one per file, one
/// after the other.
class RecordingUploadController extends Notifier<RecordingUploadState> {
  RecordingUploadController(this.uploadKey);

  /// Which upload this is, e.g. a row of the upload page.
  final String uploadKey;

  List<AudioUpload> _uploads = const [];
  List<double> _progress = const [];
  var _cancelRequested = false;

  @override
  RecordingUploadState build() {
    // Leaving the screen stops the upload; start() then deletes the
    // document.
    ref.onDispose(() {
      _cancelRequested = true;
      _cancelUploads();
    });
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
    final sheikhExtension = request.sheikhFileExtension?.toLowerCase() ?? '';
    final sheikhContentType = AudioFormats.contentTypeFor(sheikhExtension);
    final refusal = _refusal(
      request,
      uploaderId,
      contentType,
      sheikhContentType,
    );
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
    final stemPaths = request.isStems
        ? _stemPathsOf(request.studentId, id, extension, sheikhExtension)
        : null;
    // Two files: the server writes the joined mp3 at the storagePath.
    final storagePath = StoragePaths.recording(
      request.studentId,
      id,
      extension: stemPaths == null
          ? extension
          : StoragePaths.defaultAudioExtension,
    );
    final files = <_File>[
      (
        path: stemPaths?.student ?? storagePath,
        source: request.source,
        contentType: contentType!,
      ),
      if (stemPaths != null)
        (
          path: stemPaths.sheikh,
          source: request.sheikhSource!,
          contentType: sheikhContentType!,
        ),
    ];
    var created = false;
    try {
      await recordings.create(
        _recording(request, id, uploaderId!, storagePath, stemPaths),
      );
      created = true;
      if (_cancelRequested) {
        throw const AppException(AppErrorCode.uploadCancelled);
      }
      _progress = List.filled(files.length, 0);
      final uploads = _uploads = [
        for (final (index, file) in files.indexed)
          storage.upload(
            storagePath: file.path,
            source: file.source,
            contentType: file.contentType,
            onProgress: (progress) => _onProgress(index, progress),
          ),
      ];
      try {
        await Future.wait([
          for (final upload in uploads) upload.done,
        ], eagerError: true);
      } on Object {
        // The first failure stops the other file at once (a cancel already
        // stopped both).
        if (!_cancelRequested) await _cancelUploads();
        rethrow;
      }
      _uploads = const [];
      if (ref.mounted) {
        state = RecordingUploadState(
          status: RecordingUploadStatus.done,
          progress: 1,
          recordingId: id,
        );
      }
      return id;
    } catch (error, stackTrace) {
      _uploads = const [];
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
    await _cancelUploads();
  }

  /// Back to idle after a finished, failed or cancelled upload.
  void reset() {
    if (!state.isUploading) state = const RecordingUploadState();
  }

  Future<void> _cancelUploads() async {
    for (final upload in _uploads) {
      await upload.cancel();
    }
  }

  /// Why [request] cannot even start, checked before anything is written.
  static AppErrorCode? _refusal(
    RecordingUploadRequest request,
    String? uploaderId,
    String? contentType,
    String? sheikhContentType,
  ) {
    if (uploaderId == null) return AppErrorCode.permissionDenied;
    if (contentType == null) return AppErrorCode.unsupportedFile;
    if (request.isStems && sheikhContentType == null) {
      return AppErrorCode.unsupportedFile;
    }
    if (!isValidAyahRange(
      request.surahNumber,
      request.ayahFrom,
      request.ayahTo,
    )) {
      return AppErrorCode.invalidData;
    }
    return null;
  }

  void _onProgress(int index, double progress) {
    if (!ref.mounted || !state.isUploading || index >= _progress.length) {
      return;
    }
    _progress[index] = progress.clamp(0, 1);
    final total = _progress.reduce((a, b) => a + b) / _progress.length;
    state = RecordingUploadState(
      status: RecordingUploadStatus.uploading,
      progress: total,
      stemProgress: _progress.length == 2
          ? (student: _progress[0], sheikh: _progress[1])
          : null,
    );
  }

  static StemPaths _stemPathsOf(
    String studentId,
    String id,
    String studentExtension,
    String sheikhExtension,
  ) => StemPaths(
    student: StoragePaths.stem(
      studentId,
      id,
      StoragePaths.stemStudent,
      extension: studentExtension,
    ),
    sheikh: StoragePaths.stem(
      studentId,
      id,
      StoragePaths.stemSheikh,
      extension: sheikhExtension,
    ),
  );

  static Recording _recording(
    RecordingUploadRequest request,
    String id,
    String uploaderId,
    String storagePath,
    StemPaths? stemPaths,
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
    // Both wait for the teacher: an official recording's voice markers, a
    // practice recitation (firestore.rules requires false).
    reviewed: false,
    source: stemPaths == null ? RecordingSource.stereo : RecordingSource.stems,
    stemPaths: stemPaths,
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

/// One file to upload: where, what, and as which content type.
typedef _File = ({String path, AudioSource source, String contentType});

final recordingUploadControllerProvider = NotifierProvider.autoDispose
    .family<RecordingUploadController, RecordingUploadState, String>(
      RecordingUploadController.new,
    );
