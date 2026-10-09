import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/common/error_view.dart';
import '../application/teacher_summary.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_page.dart';
import 'widgets/teacher_details_view.dart';

/// One teacher: account, halaqat, password reset and disable / enable.
class TeacherDetailsScreen extends ConsumerWidget {
  const TeacherDetailsScreen({super.key, required this.teacherId});

  final String teacherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(teacherSummaryProvider(teacherId));
    return AdminPage(
      title: summary.value?.teacher.fullName ?? AppStrings.adminNavTeachers,
      body: AdminAsyncView(
        value: summary,
        builder: (context, summary) => summary == null
            ? const ErrorView(error: AppException(AppErrorCode.notFound))
            : TeacherDetailsView(summary: summary),
      ),
    );
  }
}
