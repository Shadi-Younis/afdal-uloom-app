import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common/app_snack_bar.dart';
import '../../../core/widgets/islamic/empty_state.dart';
import '../application/admin_data_providers.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_page.dart';
import 'widgets/content_width.dart';
import 'widgets/halaqa_form.dart';

/// Creates a halaqa, then opens it (to add its students next).
class CreateHalaqaScreen extends ConsumerWidget {
  const CreateHalaqaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminPage(
      title: AppStrings.newHalaqaTitle,
      body: AdminAsyncView(
        value: ref.watch(activeTeachersProvider),
        builder: (context, teachers) => teachers.isEmpty
            ? EmptyState(
                message: AppStrings.noActiveTeachers,
                actionLabel: AppStrings.addTeacher,
                onAction: () => context.go(AppRoutes.adminNewTeacher),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                child: ContentWidth(
                  child: HalaqaForm(
                    teachers: teachers,
                    onCreated: (id) {
                      showAppSnackBar(context, AppStrings.halaqaCreated);
                      context.go(AppRoutes.adminHalaqa(id));
                    },
                  ),
                ),
              ),
      ),
    );
  }
}
