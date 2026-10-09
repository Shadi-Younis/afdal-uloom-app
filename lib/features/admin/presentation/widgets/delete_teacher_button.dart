import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common/app_snack_bar.dart';
import '../../../../core/widgets/common/confirm_dialog.dart';
import '../../../../core/widgets/common/loading_button.dart';
import '../../application/delete_user_controller.dart';
import '../../application/teacher_summary.dart';
import 'blocked_delete_dialog.dart';

/// "حذف المعلم". While they teach halaqat it explains that each must get
/// another teacher first ("تغيير المعلم"), with a link to each halaqa; a
/// teacher without halaqat is deleted after a confirmation, then the
/// teachers list opens.
class DeleteTeacherButton extends ConsumerWidget {
  const DeleteTeacherButton({super.key, required this.summary});

  final TeacherSummary summary;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final teacher = summary.teacher;
    if (summary.halaqat.isNotEmpty) {
      return showBlockedDeleteDialog(
        context,
        title: AppStrings.cannotDeleteTeacher,
        message: AppStrings.teacherHasHalaqat,
        links: [
          for (final halaqa in summary.halaqat)
            (
              label: halaqa.name,
              onTap: () => context.push(AppRoutes.adminHalaqa(halaqa.id)),
            ),
        ],
      );
    }
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.deleteTeacher,
      message: AppStrings.deleteTeacherConfirm(teacher.fullName),
      confirmLabel: AppStrings.deleteTeacher,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    // Looked up now: the page shows "not found" once the teacher is gone.
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final deleted = await ref
        .read(deleteUserControllerProvider(teacher.id).notifier)
        .delete();
    if (deleted == null) return;
    router.go(AppRoutes.adminTeachers);
    showAppSnackBarOn(messenger, AppStrings.teacherDeleted);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = deleteUserControllerProvider(summary.teacher.id);
    ref.listen(provider, (_, next) {
      if (next case AsyncError(:final error)) showErrorSnackBar(context, error);
    });
    return LoadingButton(
      filled: false,
      destructive: true,
      label: AppStrings.deleteTeacher,
      icon: Icons.person_remove_outlined,
      loading: ref.watch(provider).isLoading,
      onPressed: () => _delete(context, ref),
    );
  }
}
