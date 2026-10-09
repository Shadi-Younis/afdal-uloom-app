// Data-layer helper: the only file outside core/data/ (and
// app/firebase_setup.dart) that imports a Firebase package.
import 'package:firebase_core/firebase_core.dart';

import 'app_exception.dart';

/// Maps a Firebase error code (Firestore, Storage, Functions or Auth) to an
/// [AppErrorCode].
AppErrorCode appErrorCodeFor(String firebaseCode) => switch (firebaseCode) {
  'permission-denied' ||
  'unauthenticated' ||
  'unauthorized' => AppErrorCode.permissionDenied,
  'not-found' || 'object-not-found' => AppErrorCode.notFound,
  'unavailable' ||
  'deadline-exceeded' ||
  'network-request-failed' ||
  'retry-limit-exceeded' => AppErrorCode.network,
  'invalid-argument' ||
  'out-of-range' ||
  'data-loss' => AppErrorCode.invalidData,
  // Storage: UploadTask.cancel().
  'canceled' => AppErrorCode.uploadCancelled,
  _ => AppErrorCode.unknown,
};

/// Wraps any error caught in the data layer as an [AppException]:
/// Firebase errors by their code, model parsing and validation errors as
/// [AppErrorCode.invalidData]. An [AppException] passes through unchanged.
AppException toAppException(Object error, [StackTrace? stackTrace]) =>
    switch (error) {
      AppException() => error,
      FirebaseException(:final code) => AppException(
        appErrorCodeFor(code),
        cause: error,
        stackTrace: stackTrace,
      ),
      FormatException() || ArgumentError() => AppException(
        AppErrorCode.invalidData,
        cause: error,
        stackTrace: stackTrace,
      ),
      _ => AppException(
        AppErrorCode.unknown,
        cause: error,
        stackTrace: stackTrace,
      ),
    };
