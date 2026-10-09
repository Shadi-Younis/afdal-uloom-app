import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/widgets/common/app_snack_bar.dart';
import '../../application/issued_credentials.dart';
import 'credentials_sheet.dart';
import 'reset_password_dialog.dart';

/// "تغيير كلمة السر" for [user]: the dialog, then the credentials sheet.
class ResetPasswordButton extends StatelessWidget {
  const ResetPasswordButton({super.key, required this.user});

  final AppUser user;

  Future<void> _reset(BuildContext context) async {
    final credentials = await showDialog<IssuedCredentials>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResetPasswordDialog(user: user),
    );
    if (credentials == null || !context.mounted) return;
    showAppSnackBar(context, AppStrings.passwordReset);
    await showCredentialsSheet(context, credentials);
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _reset(context),
      icon: const Icon(Icons.lock_reset),
      label: const Text(AppStrings.resetPassword),
    );
  }
}
