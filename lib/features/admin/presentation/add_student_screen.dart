import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common/app_snack_bar.dart';
import '../../../core/widgets/islamic/empty_state.dart';
import '../application/add_student_controller.dart';
import '../application/issued_credentials.dart';
import 'widgets/admin_async_view.dart';
import '../../../core/widgets/islamic/app_card.dart';
import '../../../core/widgets/islamic/app_page_scaffold.dart';
import 'widgets/content_width.dart';
import 'widgets/credentials_sheet.dart';
import 'widgets/student_form.dart';

/// Creates a student account and shows its login details once. Opened
/// from a halaqa, that halaqa is chosen already.
class AddStudentScreen extends ConsumerWidget {
  const AddStudentScreen({super.key, this.initialHalaqaId});

  final String? initialHalaqaId;

  Future<void> _created(
    BuildContext context,
    IssuedCredentials credentials,
  ) async {
    showAppSnackBar(context, AppStrings.studentCreated);
    await showCredentialsSheet(context, credentials);
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.adminStudents);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPageScaffold(
      title: AppStrings.newStudentTitle,
      body: AdminAsyncView(
        value: ref.watch(addStudentChoicesProvider),
        builder: (context, choices) => choices.halaqat.isEmpty
            ? EmptyState(
                message: AppStrings.createHalaqaFirst,
                actionLabel: AppStrings.createHalaqa,
                onAction: () => context.push(AppRoutes.adminNewHalaqa),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ContentWidth(
                  child: AppCard(
                    child: StudentForm(
                      halaqat: choices.halaqat,
                      suggestedCode: choices.suggestedCode,
                      initialHalaqaId: initialHalaqaId,
                      onCreated: (c) => _created(context, c),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
