import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../application/teacher_summary.dart';
import 'account_info.dart';
import 'content_width.dart';
import 'danger_section.dart';
import 'delete_teacher_button.dart';
import 'disable_account_button.dart';
import 'edit_profile_button.dart';
import 'reset_password_button.dart';
import 'section_card.dart';

/// The content of the teacher details page.
class TeacherDetailsView extends StatelessWidget {
  const TeacherDetailsView({super.key, required this.summary});

  final TeacherSummary summary;

  @override
  Widget build(BuildContext context) {
    final teacher = summary.teacher;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AccountInfo(
              title: AppStrings.teacherInfo,
              user: teacher,
              actions: [
                EditProfileButton(user: teacher),
                ResetPasswordButton(user: teacher),
                DisableAccountButton(user: teacher),
              ],
            ),
            SectionCard(
              title: AppStrings.teacherHalaqat,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (summary.halaqat.isEmpty)
                    const Text(AppStrings.withoutHalaqa),
                  for (final halaqa in summary.halaqat)
                    ListTile(
                      leading: const Icon(Icons.groups_outlined),
                      title: Text(halaqa.name),
                      trailing: const Icon(Icons.chevron_right),
                      contentPadding: EdgeInsets.zero,
                      onTap: () =>
                          context.push(AppRoutes.adminHalaqa(halaqa.id)),
                    ),
                ],
              ),
            ),
            DangerSection(
              hint: AppStrings.deleteTeacherHint,
              button: DeleteTeacherButton(summary: summary),
            ),
          ],
        ),
      ),
    );
  }
}
