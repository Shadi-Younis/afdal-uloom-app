import '../errors/app_exception.dart';
import '../models/audio_source.dart';
import 'audio_upload.dart';

/// Recording audio files in Cloud Storage. There is no delete: a Cloud
/// Function removes the file when its recording document is deleted.
abstract class AudioStorageService {
  /// Starts uploading [source] to [storagePath] (StoragePaths.recording)
  /// with [contentType] (AudioFormats.contentTypes). [onProgress] gets 0..1.
  /// Await the returned upload's `done`; it can be cancelled.
  ///
  /// Allowed only for the `uploadedBy` of the recording document whose
  /// storagePath this is, once, for audio under AudioFormats.maxUploadBytes
  /// (storage.rules); otherwise `done` throws [AppException].
  AudioUpload upload({
    required String storagePath,
    required AudioSource source,
    required String contentType,
    void Function(double progress)? onProgress,
  });

  /// A URL the player can stream [storagePath] from. Kept in memory for the
  /// session; [refresh] asks Storage again, e.g. after the player failed to
  /// load the cached one (its token may have been revoked).
  ///
  /// Allowed for: admins, the recording's teacher and its student
  /// (storage.rules); otherwise throws [AppException] with
  /// [AppErrorCode.permissionDenied]. A missing file throws
  /// [AppErrorCode.notFound].
  Future<Uri> getPlaybackUrl(String storagePath, {bool refresh = false});
}
