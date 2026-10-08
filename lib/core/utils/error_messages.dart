import '../constants/app_strings.dart';
import '../errors/app_exception.dart';

/// The Arabic text to show the user for [code].
String errorMessageFor(AppErrorCode code) => switch (code) {
  AppErrorCode.permissionDenied => AppStrings.errorPermissionDenied,
  AppErrorCode.notFound => AppStrings.errorNotFound,
  AppErrorCode.network => AppStrings.errorNetwork,
  AppErrorCode.invalidData => AppStrings.errorInvalidData,
  AppErrorCode.unknown => AppStrings.errorUnknown,
};
