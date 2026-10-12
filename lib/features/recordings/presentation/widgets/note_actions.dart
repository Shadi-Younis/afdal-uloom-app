import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/feedback_note.dart';
import '../../../../core/widgets/common/app_snack_bar.dart';
import '../../../../core/widgets/common/confirm_dialog.dart';
import '../../application/recording_manage_controller.dart';
import 'note_dialog.dart';

/// Edit («تعديل», or «إضافة نص» on a voice marker without text) and delete
/// (after a confirmation) for one note, for the recording's teacher and
/// admins.
class NoteActions extends ConsumerWidget {
  const NoteActions({super.key, required this.recordingId, required this.note});

  final String recordingId;
  final FeedbackNote note;

  Future<void> _edit(BuildContext context) async {
    final saved = await showNoteDialog(
      context,
      recordingId: recordingId,
      note: note,
    );
    if (saved && context.mounted) {
      showAppSnackBar(context, AppStrings.noteSaved);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.deleteNote,
      message: AppStrings.deleteNoteConfirm,
      confirmLabel: AppStrings.deleteNote,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final deleted = await ref
        .read(recordingManageControllerProvider(recordingId).notifier)
        .deleteNote(note.id);
    if (deleted) showAppSnackBarOn(messenger, AppStrings.noteDeleted);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref
        .watch(recordingManageControllerProvider(recordingId))
        .isLoading;
    final addText = note.isVoice && note.note.isEmpty;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: addText ? AppStrings.addTextToVoice : AppStrings.editNote,
          onPressed: busy ? null : () => _edit(context),
          icon: Icon(addText ? Icons.note_add_outlined : Icons.edit_outlined),
        ),
        IconButton(
          tooltip: AppStrings.deleteNote,
          onPressed: busy ? null : () => _delete(context, ref),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}
