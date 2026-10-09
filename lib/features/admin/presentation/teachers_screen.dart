import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/async_value_combine.dart';
import '../../../core/widgets/common/account_button.dart';
import '../../../core/widgets/common/logout_button.dart';
import '../../../core/widgets/islamic/app_card.dart';
import '../../../core/widgets/islamic/app_page_scaffold.dart';
import '../../../core/widgets/islamic/empty_state.dart';
import '../application/admin_data_providers.dart';
import '../application/teacher_summary.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admins_section.dart';
import 'widgets/teacher_tile.dart';

/// Every teacher, with their halaqat; disabled ones marked. The school's
/// admins are listed below them.
class TeachersScreen extends ConsumerWidget {
  const TeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void add() => context.push(AppRoutes.adminNewTeacher);
    final data = combine2(
      ref.watch(teacherSummariesProvider),
      ref.watch(adminAdminsProvider),
      (teachers, admins) => (teachers: teachers, admins: admins),
    );
    return AppPageScaffold(
      actions: const [AccountButton(), LogoutButton()],
      title: AppStrings.adminNavTeachers,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text(AppStrings.addTeacher),
      ),
      body: AdminAsyncView(
        value: data,
        builder: (context, data) {
          final admins = AdminsSection(admins: data.admins);
          const padding = EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.spaceXS,
            AppSizes.pagePadding,
            AppSizes.fabClearance,
          );
          if (data.teachers.isEmpty) {
            return ListView(
              padding: padding,
              children: [
                EmptyState(
                  message: AppStrings.noTeachers,
                  actionLabel: AppStrings.addTeacher,
                  onAction: add,
                ),
                admins,
              ],
            );
          }
          return ListView(
            padding: padding,
            children: [
              for (final summary in data.teachers) ...[
                AppCard(
                  padding: EdgeInsets.zero,
                  child: TeacherTile(
                    summary: summary,
                    onTap: () => context.push(
                      AppRoutes.adminTeacher(summary.teacher.id),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spaceS),
              ],
              const SizedBox(height: AppSizes.spaceS),
              admins,
            ],
          );
        },
      ),
    );
  }
}
