import 'package:flutter/material.dart';

import '../../../../core/application/sign_out_reason.dart';
import '../../../../core/constants/app_strings.dart';

/// Why the app signed the user out by itself, under the login form.
class SignOutNoticeText extends StatelessWidget {
  const SignOutNoticeText(this.reason, {super.key});

  final SignOutReason reason;

  static String messageFor(SignOutReason reason) => switch (reason) {
    SignOutReason.accountInactive => AppStrings.accountNoLongerActive,
  };

  @override
  Widget build(BuildContext context) {
    return Text(
      messageFor(reason),
      textAlign: TextAlign.center,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}
