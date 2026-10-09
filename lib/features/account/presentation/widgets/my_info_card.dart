import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/widgets/islamic/app_card.dart';
import '../../../../core/widgets/islamic/ornament_divider.dart';

/// "بياناتي": the signed-in user's name, username and role. Only an admin
/// changes them (the user asks the school).
class MyInfoCard extends StatelessWidget {
  const MyInfoCard({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final role = switch (user.role) {
      UserRole.admin => AppStrings.roleNameAdmin,
      UserRole.teacher => AppStrings.roleNameTeacher,
      UserRole.student => AppStrings.roleNameStudent,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OrnamentDivider(title: AppStrings.myInfo),
        const SizedBox(height: AppSizes.spaceXS),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Row(label: AppStrings.nameLabel, value: user.fullName),
              _Row(
                label: AppStrings.usernameLabel,
                value: user.username,
                ltr: true,
              ),
              _Row(label: AppStrings.roleLabel, value: role),
            ],
          ),
        ),
      ],
    );
  }
}

/// "label: value", the label at the start and the value at the end.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.ltr = false});

  final String label;
  final String value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceXS),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSizes.spaceS),
          Expanded(
            // The box sits at the end, whatever the text's own direction.
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                value,
                textDirection: ltr ? TextDirection.ltr : null,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
