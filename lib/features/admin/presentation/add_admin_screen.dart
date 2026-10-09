import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/user_role.dart';
import '../../../core/widgets/common/app_snack_bar.dart';
import '../../../core/widgets/islamic/app_card.dart';
import '../../../core/widgets/islamic/app_page_scaffold.dart';
import '../application/issued_credentials.dart';
import 'widgets/content_width.dart';
import 'widgets/credentials_sheet.dart';
import 'widgets/teacher_form.dart';

/// Creates a second (backup) admin account and shows its login details
/// once. Same fields as a teacher.
class AddAdminScreen extends StatelessWidget {
  const AddAdminScreen({super.key});

  Future<void> _created(
    BuildContext context,
    IssuedCredentials credentials,
  ) async {
    showAppSnackBar(context, AppStrings.adminCreated);
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
    return AppPageScaffold(
      title: AppStrings.newAdminTitle,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: ContentWidth(
          child: AppCard(
            child: TeacherForm(
              role: UserRole.admin,
              onCreated: (c) => _created(context, c),
            ),
          ),
        ),
      ),
    );
  }
}
