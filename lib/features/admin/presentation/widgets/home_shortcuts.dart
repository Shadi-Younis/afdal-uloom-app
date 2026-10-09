import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';

/// The home screen's buttons for the three most common tasks: the first
/// filled, the others outlined. Each form opens on top of the home (push),
/// so back returns here.
class HomeShortcuts extends StatelessWidget {
  const HomeShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.adminNewStudent),
          icon: const Icon(Icons.add),
          label: const Text(AppStrings.addStudent),
        ),
        const SizedBox(height: AppSizes.spaceS),
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.adminNewTeacher),
          icon: const Icon(Icons.add),
          label: const Text(AppStrings.addTeacher),
        ),
        const SizedBox(height: AppSizes.spaceS),
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.adminNewHalaqa),
          icon: const Icon(Icons.add),
          label: const Text(AppStrings.createHalaqa),
        ),
      ],
    );
  }
}
