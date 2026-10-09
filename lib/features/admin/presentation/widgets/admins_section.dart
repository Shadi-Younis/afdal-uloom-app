import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/widgets/islamic/app_card.dart';
import '../../../../core/widgets/islamic/ornament_divider.dart';
import 'disabled_chip.dart';

/// The school's admins under the teachers list: one card each (opens their
/// page) and "إضافة مدير" for a backup admin.
class AdminsSection extends StatelessWidget {
  const AdminsSection({super.key, required this.admins});

  final List<AppUser> admins;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OrnamentDivider(title: AppStrings.adminsTitle),
        const SizedBox(height: AppSizes.spaceXS),
        Text(
          AppStrings.adminsHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        for (final admin in admins) ...[
          const SizedBox(height: AppSizes.spaceS),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.admin_panel_settings_outlined),
              ),
              title: Text(admin.fullName),
              subtitle: Text(admin.username),
              trailing: admin.disabled ? const DisabledChip() : null,
              onTap: () => context.push(AppRoutes.adminAdmin(admin.id)),
            ),
          ),
        ],
        const SizedBox(height: AppSizes.spaceS),
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.adminNewAdmin),
          icon: const Icon(Icons.add_moderator_outlined),
          label: const Text(AppStrings.addAdmin),
        ),
      ],
    );
  }
}
