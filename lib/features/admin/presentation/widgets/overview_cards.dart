import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../application/admin_overview.dart';
import 'admin_async_view.dart';
import 'summary_card.dart';

/// The three counts of the home screen: halaqat, active teachers, active
/// students.
class OverviewCards extends ConsumerWidget {
  const OverviewCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminAsyncView(
      value: ref.watch(adminOverviewProvider),
      builder: (context, overview) => Row(
        children: [
          Expanded(
            child: SummaryCard(
              count: overview.halaqat,
              label: AppStrings.adminNavHalaqat,
              icon: Icons.groups_outlined,
              onTap: () => context.go(AppRoutes.adminHalaqat),
            ),
          ),
          const SizedBox(width: AppSizes.spaceS),
          Expanded(
            child: SummaryCard(
              count: overview.activeTeachers,
              label: AppStrings.adminNavTeachers,
              icon: Icons.person_outline,
              onTap: () => context.go(AppRoutes.adminTeachers),
            ),
          ),
          const SizedBox(width: AppSizes.spaceS),
          Expanded(
            child: SummaryCard(
              count: overview.activeStudents,
              label: AppStrings.adminNavStudents,
              icon: Icons.school_outlined,
              onTap: () => context.go(AppRoutes.adminStudents),
            ),
          ),
        ],
      ),
    );
  }
}
