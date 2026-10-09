import '../errors/app_exception.dart';

/// A running upload started by AudioStorageService.upload.
abstract class AudioUpload {
  /// Completes when the file is stored. Throws [AppException]: with
  /// [AppErrorCode.uploadCancelled] after [cancel], [AppErrorCode.fileTooLarge]
  /// or [AppErrorCode.unsupportedFile] before anything is sent, or the code
  /// of a Storage failure.
  Future<void> get done;

  /// Stops the upload; [done] then throws [AppErrorCode.uploadCancelled].
  /// Does nothing once [done] has completed.
  Future<void> cancel();
}
