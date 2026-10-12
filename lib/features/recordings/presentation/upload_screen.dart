import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/my_students_providers.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common/confirm_dialog.dart';
import '../../../core/widgets/islamic/app_page_scaffold.dart';
import '../../../core/widgets/islamic/error_state.dart';
import '../../../core/widgets/islamic/loading_state.dart';
import '../application/upload_batch_controller.dart';
import 'widgets/upload_batch_view.dart';

/// «رفع تسجيلات», for the teacher (his students) and the admin (every
/// student), on the web and on phones alike: pick (or, on the web, drop)
/// studio files, check what their names filled in, and upload them all.
/// [studentId] (opened from a student's page) fills in that student.
/// Leaving while files upload asks first.
class UploadScreen extends ConsumerWidget {
  const UploadScreen({super.key, this.studentId});

  final String? studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(myStudentsProvider);
    final running = ref.watch(
      uploadBatchControllerProvider(studentId).select((s) => s.running),
    );
    return AppPageScaffold(
      title: AppStrings.uploadRecordings,
      leaveGuard: running
          ? () => showConfirmDialog(
              context,
              title: AppStrings.leaveUploadTitle,
              message: AppStrings.leaveUploadMessage,
              confirmLabel: AppStrings.leave,
              destructive: true,
            )
          : null,
      body: switch (students) {
        AsyncData(value: final list) => UploadBatchView(
          students: list,
          defaultStudentId: studentId,
        ),
        AsyncError(:final error) => ErrorState(
          error: error,
          onRetry: () => ref.invalidate(myHalaqatProvider),
        ),
        _ => const LoadingState(),
      },
    );
  }
}
