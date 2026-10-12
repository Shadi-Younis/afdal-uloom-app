import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common/app_snack_bar.dart';
import '../../../../core/widgets/common/confirm_dialog.dart';
import '../../../../core/widgets/common/loading_button.dart';
import '../../../../core/widgets/islamic/app_top_bar.dart';
import '../../application/recording_manage_controller.dart';

/// «حذف التدريب»: the student takes back a practice recording the sheikh
/// has not reviewed yet, after confirming, and goes back to his list.
class DeletePracticeButton extends ConsumerWidget {
  const DeletePracticeButton({super.key, required this.recordingId});

  final String recordingId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.deletePractice,
      message: AppStrings.deletePracticeMessage,
      confirmLabel: AppStrings.deletePractice,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    // Looked up now: once deleted, this page shows "not found" before the
    // call returns.
    final back = AppTopBar.backTarget(context);
    final messenger = ScaffoldMessenger.of(context);
    final done = await ref
        .read(recordingManageControllerProvider(recordingId).notifier)
        .deleteRecording();
    if (!done) return;
    back?.call();
    showAppSnackBarOn(messenger, AppStrings.practiceDeleted);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = recordingManageControllerProvider(recordingId);
    // A student has no other action on the page that reports this
    // controller's errors (ReviewedToggle does it for the teacher).
    ref.listen(provider, (_, next) {
      if (next case AsyncError(:final error)) showErrorSnackBar(context, error);
    });
    return LoadingButton(
      filled: false,
      destructive: true,
      label: AppStrings.deletePractice,
      icon: Icons.delete_outline,
      loading: ref.watch(provider).isLoading,
      onPressed: () => _delete(context, ref),
    );
  }
}
