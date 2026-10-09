import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_digits.dart';
import '../../../../core/widgets/common/app_snack_bar.dart';
import '../../../../core/widgets/common/confirm_dialog.dart';
import '../../../../core/widgets/common/loading_button.dart';
import '../../application/delete_halaqa_controller.dart';
import '../../application/halaqa_summary.dart';
import 'blocked_delete_dialog.dart';

/// "حذف الحلقة". With students (disabled ones included) it explains that
/// they must move first, with a link to them; an empty halaqa is deleted
/// after a confirmation, then the halaqat list opens.
class DeleteHalaqaButton extends ConsumerWidget {
  const DeleteHalaqaButton({super.key, required this.summary});

  final HalaqaSummary summary;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final halaqa = summary.halaqa;
    if (summary.students.isNotEmpty) {
      return showBlockedDeleteDialog(
        context,
        title: AppStrings.cannotDeleteHalaqa,
        message: AppStrings.halaqaHasStudents(
          toArabicDigits(summary.students.length),
        ),
        actions: [
          (
            label: AppStrings.showStudents,
            onTap: () => context.go(AppRoutes.adminStudentsOfHalaqa(halaqa.id)),
          ),
        ],
      );
    }
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.deleteHalaqa,
      message: AppStrings.deleteHalaqaConfirm(halaqa.name),
      confirmLabel: AppStrings.deleteHalaqa,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    // Looked up now: once deleted, this page shows "not found" and the
    // button is gone before the call returns.
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final done = await ref
        .read(deleteHalaqaControllerProvider(halaqa.id).notifier)
        .delete();
    if (!done) return;
    router.go(AppRoutes.adminHalaqat);
    showAppSnackBarOn(messenger, AppStrings.halaqaDeleted);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = deleteHalaqaControllerProvider(summary.halaqa.id);
    ref.listen(provider, (_, next) {
      if (next case AsyncError(:final error)) showErrorSnackBar(context, error);
    });
    return LoadingButton(
      filled: false,
      destructive: true,
      label: AppStrings.deleteHalaqa,
      icon: Icons.delete_outline,
      loading: ref.watch(provider).isLoading,
      onPressed: () => _delete(context, ref),
    );
  }
}
