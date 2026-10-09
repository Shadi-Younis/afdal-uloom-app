import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../application/students_filter_controller.dart';
import 'admin_async_view.dart';
import 'student_tile.dart';

/// The students that match the search and halaqa filter.
class StudentsList extends ConsumerWidget {
  const StudentsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminAsyncView(
      value: ref.watch(filteredStudentsProvider),
      builder: (context, students) => students.isEmpty
          ? const EmptyView(
              icon: Icons.search_off,
              message: AppStrings.noResults,
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: AppSizes.fabClearance),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: students.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final summary = students[i];
                return StudentTile(
                  student: summary.student,
                  halaqaName: summary.halaqa?.name ?? AppStrings.withoutHalaqa,
                  onTap: () =>
                      context.go(AppRoutes.adminStudent(summary.student.id)),
                );
              },
            ),
    );
  }
}
