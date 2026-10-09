import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/islamic/stat_card.dart';
import '../../application/admin_overview.dart';
import 'admin_async_view.dart';

/// The three counts of the home screen: halaqat, active teachers, active
/// students. A tap switches to that section's tab.
class OverviewCards extends ConsumerWidget {
  const OverviewCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminAsyncView(
      value: ref.watch(adminOverviewProvider),
      builder: (context, overview) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StatCard(
              number: overview.halaqat,
              label: AppStrings.adminNavHalaqat,
              onTap: () => context.go(AppRoutes.adminHalaqat),
            ),
          ),
          const SizedBox(width: AppSizes.spaceS),
          Expanded(
            child: StatCard(
              number: overview.activeTeachers,
              label: AppStrings.adminNavTeachers,
              onTap: () => context.go(AppRoutes.adminTeachers),
            ),
          ),
          const SizedBox(width: AppSizes.spaceS),
          Expanded(
            child: StatCard(
              number: overview.activeStudents,
              label: AppStrings.adminNavStudents,
              onTap: () => context.go(AppRoutes.adminStudents),
            ),
          ),
        ],
      ),
    );
  }
}
