import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/recording.dart';
import '../../../../core/models/recording_type.dart';
import '../../../../core/widgets/common/app_snack_bar.dart';
import '../../../../core/widgets/common/confirm_dialog.dart';
import '../../../../core/widgets/common/loading_button.dart';
import '../../../../core/widgets/islamic/app_top_bar.dart';
import '../../application/recording_manage_controller.dart';

/// Deletes [recording] after confirming, then goes back to the previous
/// page: «حذف التسجيل» for an official recording (its teacher, admins;
/// also while a two-file recording waits or after its join failed),
/// «حذف التدريب» for a practice (its student). The server removes the
/// files and the notes (onRecordingDeleted).
class DeleteRecordingButton extends ConsumerWidget {
  const DeleteRecordingButton({super.key, required this.recording});

  final Recording recording;

  bool get _isPractice => recording.type == RecordingType.practice;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final label = _isPractice
        ? AppStrings.deletePractice
        : AppStrings.deleteRecording;
    final confirmed = await showConfirmDialog(
      context,
      title: label,
      message: _isPractice
          ? AppStrings.deletePracticeMessage
          : AppStrings.deleteRecordingMessage,
      confirmLabel: label,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    // Looked up now: once deleted, this page shows "not found" before the
    // call returns.
    final back = AppTopBar.backTarget(context);
    final messenger = ScaffoldMessenger.of(context);
    final done = await ref
        .read(recordingManageControllerProvider(recording.id).notifier)
        .deleteRecording();
    if (!done) return;
    back?.call();
    showAppSnackBarOn(
      messenger,
      _isPractice ? AppStrings.practiceDeleted : AppStrings.recordingDeleted,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LoadingButton(
      filled: false,
      destructive: true,
      label: _isPractice
          ? AppStrings.deletePractice
          : AppStrings.deleteRecording,
      icon: Icons.delete_outline,
      loading: ref
          .watch(recordingManageControllerProvider(recording.id))
          .isLoading,
      onPressed: () => _delete(context, ref),
    );
  }
}
