import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_digits.dart';
import '../../application/halaqa_summary.dart';
import 'change_teacher_button.dart';
import 'content_width.dart';
import 'info_row.dart';
import 'rename_halaqa_button.dart';
import 'section_card.dart';
import 'student_tile.dart';

/// The content of the halaqa details page.
class HalaqaDetailsView extends StatelessWidget {
  const HalaqaDetailsView({super.key, required this.summary});

  final HalaqaSummary summary;

  @override
  Widget build(BuildContext context) {
    final halaqa = summary.halaqa;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionCard(
              title: AppStrings.halaqaLabel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InfoRow(
                    label: AppStrings.halaqaNameLabel,
                    value: halaqa.name,
                  ),
                  InfoRow(
                    label: AppStrings.teacherLabel,
                    value:
                        summary.teacher?.fullName ?? AppStrings.unknownTeacher,
                  ),
                  const SizedBox(height: AppSizes.spaceS),
                  RenameHalaqaButton(halaqa: halaqa),
                  const SizedBox(height: AppSizes.spaceS),
                  ChangeTeacherButton(summary: summary),
                ],
              ),
            ),
            SectionCard(
              title:
                  '${AppStrings.halaqaStudents} (${toArabicDigits(summary.students.length)})',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (summary.students.isEmpty)
                    const Text(AppStrings.noStudentsInHalaqa),
                  for (final student in summary.students)
                    StudentTile(
                      student: student,
                      onTap: () => context.push(
                        AppRoutes.adminHalaqaStudent(halaqa.id, student.id),
                      ),
                    ),
                  const SizedBox(height: AppSizes.spaceS),
                  FilledButton.icon(
                    onPressed: () => context.push(
                      AppRoutes.adminHalaqaAddStudent(halaqa.id),
                    ),
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text(AppStrings.addStudent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
