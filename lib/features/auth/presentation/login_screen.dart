import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common/school_logo.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          // Scrolls instead of overflowing on short screens or large text.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SchoolLogo(size: AppSizes.logoLarge),
                const SizedBox(height: AppSizes.spaceL),
                Text(
                  AppStrings.loginTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSizes.spaceXL),
                // TODO: remove after auth
                FilledButton(
                  onPressed: () => context.go(AppRoutes.admin),
                  child: const Text(AppStrings.loginAsAdmin),
                ),
                const SizedBox(height: AppSizes.spaceS),
                // TODO: remove after auth
                FilledButton(
                  onPressed: () => context.go(AppRoutes.teacher),
                  child: const Text(AppStrings.loginAsTeacher),
                ),
                const SizedBox(height: AppSizes.spaceS),
                // TODO: remove after auth
                FilledButton(
                  onPressed: () => context.go(AppRoutes.student),
                  child: const Text(AppStrings.loginAsStudent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
