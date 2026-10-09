import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';

/// The home screen's buttons for the three most common tasks.
class HomeShortcuts extends StatelessWidget {
  const HomeShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => context.go(AppRoutes.adminNewStudent),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text(AppStrings.addStudent),
        ),
        const SizedBox(height: AppSizes.spaceS),
        FilledButton.tonalIcon(
          onPressed: () => context.go(AppRoutes.adminNewTeacher),
          icon: const Icon(Icons.person_add_outlined),
          label: const Text(AppStrings.addTeacher),
        ),
        const SizedBox(height: AppSizes.spaceS),
        FilledButton.tonalIcon(
          onPressed: () => context.go(AppRoutes.adminNewHalaqa),
          icon: const Icon(Icons.group_add_outlined),
          label: const Text(AppStrings.createHalaqa),
        ),
      ],
    );
  }
}
