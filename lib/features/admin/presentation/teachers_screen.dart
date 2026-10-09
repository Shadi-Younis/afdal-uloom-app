import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/islamic/empty_state.dart';
import '../application/teacher_summary.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_page.dart';
import 'widgets/teacher_tile.dart';

/// Every teacher, with their halaqat; disabled ones marked.
class TeachersScreen extends ConsumerWidget {
  const TeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void add() => context.go(AppRoutes.adminNewTeacher);
    return AdminPage(
      title: AppStrings.adminNavTeachers,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text(AppStrings.addTeacher),
      ),
      body: AdminAsyncView(
        value: ref.watch(teacherSummariesProvider),
        builder: (context, teachers) => teachers.isEmpty
            ? EmptyState(
                message: AppStrings.noTeachers,
                actionLabel: AppStrings.addTeacher,
                onAction: add,
              )
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: AppSizes.fabClearance),
                itemCount: teachers.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => TeacherTile(
                  summary: teachers[i],
                  onTap: () => context.go(
                    AppRoutes.adminTeacher(teachers[i].teacher.id),
                  ),
                ),
              ),
      ),
    );
  }
}
