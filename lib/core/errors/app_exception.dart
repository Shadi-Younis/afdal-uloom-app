/// What went wrong, in terms the UI can act on. Each code has an Arabic
/// message (see `errorMessageFor` in core/utils/error_messages.dart).
enum AppErrorCode {
  /// Security rules refused, or the user is signed out.
  permissionDenied,

  /// The document or file does not exist.
  notFound,

  /// The server could not be reached; retrying may help.
  network,

  /// A document does not match the data model, or the server rejected the
  /// values sent.
  invalidData,

  /// Wrong username or password.
  invalidCredentials,

  /// The account was disabled by an admin.
  accountDisabled,

  /// Too many failed sign-ins; Firebase blocks for a while.
  tooManyAttempts,

  /// Signed in, but the account has no valid role claim.
  noRole,

  /// The username is already taken.
  usernameTaken,

  /// The student code is already taken.
  studentCodeTaken,

  /// The operation does not fit the current data, e.g. moving a user who is
  /// not a student.
  failedPrecondition,

  /// An audio file at or over AudioFormats.maxUploadBytes.
  fileTooLarge,

  /// Not an audio file the app accepts (see AudioFormats.contentTypes), or
  /// an empty one.
  unsupportedFile,

  /// The user cancelled an upload.
  uploadCancelled,

  /// Anything else.
  unknown,
}

/// The only exception the data layer throws. Repositories catch Firebase
/// errors and rethrow them as this, so nothing above the data layer depends
/// on Firebase error types.
class AppException implements Exception {
  const AppException(this.code, {this.cause, this.stackTrace});

  /// [error] itself when it already is an [AppException], otherwise an
  /// [AppErrorCode.unknown] one wrapping it. For callers that must never
  /// expose another error type, whatever an implementation throws.
  factory AppException.wrap(Object error, [StackTrace? stackTrace]) =>
      error is AppException
      ? error
      : AppException(
          AppErrorCode.unknown,
          cause: error,
          stackTrace: stackTrace,
        );

  final AppErrorCode code;

  /// The original error, for logs only; never show it to the user.
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppException(${code.name}): $cause';
}
