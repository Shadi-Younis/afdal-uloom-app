import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/common/error_view.dart';
import '../application/student_summary.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_page.dart';
import 'widgets/student_details_view.dart';

/// One student: account, halaqa, password reset, move, disable / enable,
/// and their recordings.
class StudentDetailsScreen extends ConsumerWidget {
  const StudentDetailsScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(studentSummaryProvider(studentId));
    return AdminPage(
      title: summary.value?.student.fullName ?? AppStrings.adminNavStudents,
      body: AdminAsyncView(
        value: summary,
        builder: (context, summary) => summary == null
            ? const ErrorView(error: AppException(AppErrorCode.notFound))
            : StudentDetailsView(summary: summary),
      ),
    );
  }
}
