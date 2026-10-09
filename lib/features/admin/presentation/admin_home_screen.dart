import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common/current_user_name.dart';
import 'widgets/admin_page.dart';
import 'widgets/content_width.dart';
import 'widgets/home_shortcuts.dart';
import 'widgets/overview_cards.dart';

/// The admin's home: a greeting, the school's counts and shortcuts to the
/// most common tasks.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AdminPage(
      title: AppStrings.adminHomeTitle,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.adminWelcome,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const CurrentUserName(),
              const SizedBox(height: AppSizes.spaceL),
              const OverviewCards(),
              const SizedBox(height: AppSizes.spaceL),
              Text(
                AppStrings.shortcutsTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSizes.spaceS),
              const HomeShortcuts(),
            ],
          ),
        ),
      ),
    );
  }
}
