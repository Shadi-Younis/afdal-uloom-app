import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common/empty_view.dart';
import '../application/student_summary.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_page.dart';
import 'widgets/students_filter_bar.dart';
import 'widgets/students_list.dart';

/// Every student by code, with search and a filter per halaqa.
class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void add() => context.go(AppRoutes.adminNewStudent);
    return AdminPage(
      title: AppStrings.adminNavStudents,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text(AppStrings.addStudent),
      ),
      body: AdminAsyncView(
        value: ref.watch(studentSummariesProvider),
        builder: (context, students) => students.isEmpty
            ? EmptyView(
                icon: Icons.school_outlined,
                message: AppStrings.noStudents,
                actionLabel: AppStrings.addStudent,
                onAction: add,
              )
            : const Column(
                children: [
                  StudentsFilterBar(),
                  Expanded(child: StudentsList()),
                ],
              ),
      ),
    );
  }
}
