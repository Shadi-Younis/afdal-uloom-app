import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/error_messages.dart';
import '../../application/login_validation_error.dart';

/// The Arabic text for a login error, shown under the form.
class LoginErrorText extends StatelessWidget {
  const LoginErrorText(this.error, {super.key});

  final Object error;

  static String messageFor(Object error) => switch (error) {
    LoginValidationError.usernameRequired => AppStrings.usernameRequired,
    LoginValidationError.passwordRequired => AppStrings.passwordRequired,
    AppException(:final code) => errorMessageFor(code),
    _ => AppStrings.errorUnknown,
  };

  @override
  Widget build(BuildContext context) {
    return Text(
      messageFor(error),
      textAlign: TextAlign.center,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}
