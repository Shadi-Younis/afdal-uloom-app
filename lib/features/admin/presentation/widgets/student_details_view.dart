import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../application/student_summary.dart';
import 'account_info.dart';
import 'content_width.dart';
import 'disable_account_button.dart';
import 'info_row.dart';
import 'move_student_button.dart';
import 'reset_password_button.dart';
import 'section_card.dart';

/// The content of the student details page.
class StudentDetailsView extends StatelessWidget {
  const StudentDetailsView({super.key, required this.summary});

  final StudentSummary summary;

  @override
  Widget build(BuildContext context) {
    final student = summary.student;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AccountInfo(
              user: student,
              extraRows: [
                InfoRow(
                  label: AppStrings.studentCodeLabel,
                  value: student.studentCode ?? '',
                  ltr: true,
                ),
                InfoRow(
                  label: AppStrings.halaqaLabel,
                  value: summary.halaqa?.name ?? AppStrings.withoutHalaqa,
                ),
              ],
              actions: [
                ResetPasswordButton(user: student),
                MoveStudentButton(summary: summary),
                DisableAccountButton(user: student),
              ],
            ),
            // Placeholder: the recordings list comes in a later task.
            const SectionCard(
              title: AppStrings.recordingsTitle,
              child: Text(AppStrings.recordingsPlaceholder),
            ),
          ],
        ),
      ),
    );
  }
}
