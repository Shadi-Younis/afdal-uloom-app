import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common/app_snack_bar.dart';
import '../application/issued_credentials.dart';
import 'widgets/admin_page.dart';
import 'widgets/content_width.dart';
import 'widgets/credentials_sheet.dart';
import 'widgets/teacher_form.dart';

/// Creates a teacher account and shows its login details once.
class AddTeacherScreen extends StatelessWidget {
  const AddTeacherScreen({super.key});

  Future<void> _created(
    BuildContext context,
    IssuedCredentials credentials,
  ) async {
    showAppSnackBar(context, AppStrings.teacherCreated);
    await showCredentialsSheet(context, credentials);
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.adminTeachers);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: AppStrings.newTeacherTitle,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: ContentWidth(
          child: TeacherForm(onCreated: (c) => _created(context, c)),
        ),
      ),
    );
  }
}
