import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/app_user.dart';
import '../../../core/widgets/common/content_width.dart';
import '../../../core/widgets/islamic/app_card.dart';
import '../../../core/widgets/islamic/app_page_scaffold.dart';
import '../../../core/widgets/islamic/error_state.dart';
import '../../../core/widgets/islamic/loading_state.dart';
import '../../../core/widgets/islamic/ornament_divider.dart';
import '../application/teacher_providers.dart';
import 'widgets/teacher_student_info.dart';
import 'widgets/teacher_student_recordings.dart';

/// A student of the teacher: name, code and halaqa, «رفع تسجيل لهذا
/// الطالب», and their recordings, newest first.
class TeacherStudentScreen extends ConsumerWidget {
  const TeacherStudentScreen({
    super.key,
    required this.halaqaId,
    required this.studentId,
  });

  final String halaqaId;
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(teacherStudentProvider(studentId));
    return AppPageScaffold(
      title: student.value?.fullName ?? AppStrings.myStudents,
      body: switch (student) {
        AsyncData(value: final AppUser student) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: TeacherStudentInfo(
                    student: student,
                    halaqaId: halaqaId,
                  ),
                ),
                const SizedBox(height: AppSizes.spaceM),
                FilledButton.icon(
                  onPressed: () => context.push(
                    AppRoutes.teacherUpload(studentId: student.id),
                  ),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text(AppStrings.uploadForStudent),
                ),
                const SizedBox(height: AppSizes.spaceS),
                const OrnamentDivider(title: AppStrings.recordingsTitle),
                const SizedBox(height: AppSizes.spaceXS),
                TeacherStudentRecordings(studentId: student.id),
              ],
            ),
          ),
        ),
        AsyncData() => const ErrorState(
          error: AppException(AppErrorCode.notFound),
        ),
        AsyncError(:final error) => ErrorState(
          error: error,
          onRetry: () => ref.invalidate(teacherStudentProvider(studentId)),
        ),
        _ => const LoadingState(),
      },
    );
  }
}
