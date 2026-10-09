import '../constants/app_strings.dart';
import '../errors/app_exception.dart';

/// The Arabic text to show the user for [code].
String errorMessageFor(AppErrorCode code) => switch (code) {
  AppErrorCode.permissionDenied => AppStrings.errorPermissionDenied,
  AppErrorCode.notFound => AppStrings.errorNotFound,
  AppErrorCode.network => AppStrings.errorNetwork,
  AppErrorCode.invalidData => AppStrings.errorInvalidData,
  AppErrorCode.invalidCredentials => AppStrings.errorInvalidCredentials,
  AppErrorCode.accountDisabled => AppStrings.errorAccountDisabled,
  AppErrorCode.tooManyAttempts => AppStrings.errorTooManyAttempts,
  AppErrorCode.noRole => AppStrings.errorNoRole,
  AppErrorCode.usernameTaken => AppStrings.errorUsernameTaken,
  AppErrorCode.studentCodeTaken => AppStrings.errorStudentCodeTaken,
  AppErrorCode.failedPrecondition => AppStrings.errorFailedPrecondition,
  AppErrorCode.fileTooLarge => AppStrings.errorFileTooLarge,
  AppErrorCode.unsupportedFile => AppStrings.errorUnsupportedFile,
  AppErrorCode.uploadCancelled => AppStrings.errorUploadCancelled,
  AppErrorCode.unknown => AppStrings.errorUnknown,
};

/// The Arabic text for any caught [error]: its code's message for an
/// [AppException], the generic one for anything else (never raw text).
String errorMessageOf(Object error) =>
    errorMessageFor(error is AppException ? error.code : AppErrorCode.unknown);
