import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/widgets/common/app_snack_bar.dart';
import 'edit_profile_dialog.dart';

/// "تعديل البيانات" for [user]: the edit dialog, then a SnackBar. The page
/// shows the new values through the users stream.
class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key, required this.user});

  final AppUser user;

  Future<void> _edit(BuildContext context) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditProfileDialog(user: user),
    );
    if (saved == true && context.mounted) {
      showAppSnackBar(context, AppStrings.profileUpdated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _edit(context),
      icon: const Icon(Icons.edit_outlined),
      label: const Text(AppStrings.editProfile),
    );
  }
}
