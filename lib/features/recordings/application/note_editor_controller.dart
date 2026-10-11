import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/session_providers.dart';
import '../../../core/constants/model_limits.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/feedback_note.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/repository_providers.dart';
import 'note_editor_state.dart';

/// The note dialog of the recording screen: a new written note at a
/// moment of the recording, or new text and rating for an existing note
/// (a voice marker's text may be empty). The repository also tells the
/// student (`unreadFeedback`) in the same batch.
class NoteEditorController extends Notifier<NoteEditorState> {
  @override
  NoteEditorState build() => const NoteEditorState();

  /// The user changed the text: its problem and the last error go.
  void edited() => state = NoteEditorState(submitting: state.submitting);

  /// Adds a written note at [atSecond]. Whether it was saved; otherwise the
  /// reason is in the state.
  Future<bool> add({
    required String recordingId,
    required int atSecond,
    required String text,
    int? rating,
  }) => _save(text, allowEmpty: false, (note) async {
    final uid = ref.read(sessionProvider).value?.uid;
    if (uid == null) throw const AppException(AppErrorCode.permissionDenied);
    await ref
        .read(feedbackRepositoryProvider)
        .add(
          recordingId,
          FeedbackNote(
            id: '',
            teacherId: uid,
            note: note,
            atSecond: atSecond,
            rating: rating,
            // Ignored: the repository sets the server time.
            createdAt: ref.read(clockProvider)(),
          ),
        );
  });

  /// Replaces the text and rating of [note].
  Future<bool> edit({
    required String recordingId,
    required FeedbackNote note,
    required String text,
    int? rating,
  }) => _save(
    text,
    allowEmpty: note.isVoice,
    (text) => ref
        .read(feedbackRepositoryProvider)
        .update(recordingId, note.id, note: text, rating: rating),
  );

  Future<bool> _save(
    String text,
    Future<void> Function(String text) send, {
    required bool allowEmpty,
  }) async {
    if (state.submitting) return false;
    final trimmed = text.trim();
    final problem = trimmed.isEmpty && !allowEmpty
        ? NoteProblem.required
        : trimmed.length > ModelLimits.noteMaxLength
        ? NoteProblem.tooLong
        : null;
    if (problem != null) {
      state = NoteEditorState(problem: problem);
      return false;
    }
    state = const NoteEditorState(submitting: true);
    try {
      await send(trimmed);
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = NoteEditorState(error: AppException.wrap(error, stackTrace));
      }
      return false;
    }
    if (ref.mounted) state = const NoteEditorState();
    return true;
  }
}

final noteEditorControllerProvider =
    NotifierProvider.autoDispose<NoteEditorController, NoteEditorState>(
      NoteEditorController.new,
    );
