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

  /// Anything else.
  unknown,
}

/// The only exception the data layer throws. Repositories catch Firebase
/// errors and rethrow them as this, so nothing above the data layer depends
/// on Firebase error types.
class AppException implements Exception {
  const AppException(this.code, {this.cause, this.stackTrace});

  final AppErrorCode code;

  /// The original error, for logs only; never show it to the user.
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppException(${code.name}): $cause';
}
