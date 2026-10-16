import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/model_limits.dart';
import '../../../../core/models/feedback_note.dart';
import '../../../../core/utils/arabic_digits.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/utils/player_format.dart';
import '../../../../core/widgets/common/loading_button.dart';
import '../../application/note_editor_controller.dart';
import '../../application/note_editor_state.dart';

/// Opens the note dialog: a new written note at [atSecond], or the text
/// of [note]. Resolves to true once saved.
Future<bool> showNoteDialog(
  BuildContext context, {
  required String recordingId,
  int? atSecond,
  FeedbackNote? note,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) =>
          NoteDialog(recordingId: recordingId, atSecond: atSecond, note: note),
    ) ??
    false;

/// The dialog of [showNoteDialog].
class NoteDialog extends ConsumerStatefulWidget {
  const NoteDialog({
    super.key,
    required this.recordingId,
    this.atSecond,
    this.note,
  });

  final String recordingId;

  /// Where a new note goes; ignored when editing [note].
  final int? atSecond;

  /// The note to edit; null for a new one.
  final FeedbackNote? note;

  @override
  ConsumerState<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends ConsumerState<NoteDialog> {
  late final _text = TextEditingController(text: widget.note?.note ?? '');

  NoteEditorController get _controller =>
      ref.read(noteEditorControllerProvider.notifier);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final note = widget.note;
    final saved = note == null
        ? await _controller.add(
            recordingId: widget.recordingId,
            atSecond: widget.atSecond ?? 0,
            text: _text.text,
          )
        : await _controller.edit(
            recordingId: widget.recordingId,
            note: note,
            text: _text.text,
          );
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(noteEditorControllerProvider);
    final theme = Theme.of(context);
    final at = widget.note?.atSecond ?? widget.atSecond;
    return PopScope(
      canPop: !state.submitting,
      child: AlertDialog(
        title: Text(
          widget.note == null
              ? AppStrings.newNoteTitle
              : AppStrings.editNoteTitle,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (at != null)
                Text(
                  AppStrings.atTime(formatClock(Duration(seconds: at))),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: AppSizes.spaceS),
              TextField(
                controller: _text,
                enabled: !state.submitting,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                onChanged: (_) => _controller.edited(),
                decoration: InputDecoration(
                  labelText: AppStrings.noteLabel,
                  alignLabelWithHint: true,
                  errorText: _problemText(state.problem),
                ),
              ),
              if (state.error case final error?)
                Text(
                  errorMessageFor(error.code),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: state.submitting
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          LoadingButton(
            label: AppStrings.save,
            loading: state.submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  static String? _problemText(NoteProblem? problem) => switch (problem) {
    null => null,
    NoteProblem.required => AppStrings.noteRequired,
    NoteProblem.tooLong => AppStrings.noteTooLong(
      toArabicDigits(ModelLimits.noteMaxLength),
    ),
  };
}
