import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/widgets/common/app_snack_bar.dart';
import '../../application/issued_credentials.dart';
import 'info_row.dart';

/// Shows the login details just created or reset, once. Closes only with
/// "تم", so the password is not lost to a stray tap.
Future<void> showCredentialsSheet(
  BuildContext context,
  IssuedCredentials credentials,
) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  isDismissible: false,
  enableDrag: false,
  builder: (context) => CredentialsSheet(credentials: credentials),
);

/// The sheet of [showCredentialsSheet]: name, username and password, and
/// "نسخ" to copy a ready Arabic message for WhatsApp.
class CredentialsSheet extends StatelessWidget {
  const CredentialsSheet({super.key, required this.credentials});

  final IssuedCredentials credentials;

  /// The text "نسخ" puts on the clipboard.
  static String messageFor(IssuedCredentials credentials) =>
      AppStrings.credentialsMessage(
        role: switch (credentials.role) {
          UserRole.student => AppStrings.roleStudent,
          UserRole.teacher => AppStrings.roleTeacher,
          UserRole.admin => AppStrings.roleAdmin,
        },
        name: credentials.fullName,
        username: credentials.username,
        password: credentials.password,
      );

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: messageFor(credentials)));
    if (context.mounted) showAppSnackBar(context, AppStrings.copied);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.credentialsTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.spaceM),
            InfoRow(label: AppStrings.nameLabel, value: credentials.fullName),
            InfoRow(
              label: AppStrings.usernameLabel,
              value: credentials.username,
              ltr: true,
            ),
            InfoRow(
              label: AppStrings.passwordLabel,
              value: credentials.password,
              ltr: true,
            ),
            const SizedBox(height: AppSizes.spaceM),
            Text(
              AppStrings.credentialsWarning,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: AppSizes.spaceL),
            FilledButton.icon(
              onPressed: () => _copy(context),
              icon: const Icon(Icons.copy),
              label: const Text(AppStrings.copy),
            ),
            const SizedBox(height: AppSizes.spaceS),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.done),
            ),
          ],
        ),
      ),
    );
  }
}
