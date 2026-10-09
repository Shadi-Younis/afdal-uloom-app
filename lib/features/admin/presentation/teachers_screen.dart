import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/islamic/empty_state.dart';
import '../application/teacher_summary.dart';
import 'widgets/admin_async_view.dart';
import '../../../core/widgets/common/logout_button.dart';
import '../../../core/widgets/islamic/app_card.dart';
import '../../../core/widgets/islamic/app_page_scaffold.dart';
import 'widgets/teacher_tile.dart';

/// Every teacher, with their halaqat; disabled ones marked.
class TeachersScreen extends ConsumerWidget {
  const TeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void add() => context.push(AppRoutes.adminNewTeacher);
    return AppPageScaffold(
      actions: const [LogoutButton()],
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
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pagePadding,
                  AppSizes.spaceXS,
                  AppSizes.pagePadding,
                  AppSizes.fabClearance,
                ),
                itemCount: teachers.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSizes.spaceS),
                itemBuilder: (context, i) => AppCard(
                  padding: EdgeInsets.zero,
                  child: TeacherTile(
                    summary: teachers[i],
                    onTap: () => context.push(
                      AppRoutes.adminTeacher(teachers[i].teacher.id),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
