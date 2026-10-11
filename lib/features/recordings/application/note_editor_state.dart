import '../../../core/errors/app_exception.dart';

/// Why the text of a note was refused before sending.
enum NoteProblem {
  /// A written note needs text.
  required,

  /// Longer than ModelLimits.noteMaxLength.
  tooLong,
}

/// The state of the note dialog: sending, a problem with the text, or a
/// failure from the server.
class NoteEditorState {
  const NoteEditorState({this.submitting = false, this.problem, this.error});

  final bool submitting;
  final NoteProblem? problem;
  final AppException? error;

  @override
  bool operator ==(Object other) =>
      other is NoteEditorState &&
      other.submitting == submitting &&
      other.problem == problem &&
      other.error?.code == error?.code;

  @override
  int get hashCode => Object.hash(submitting, problem, error?.code);

  @override
  String toString() =>
      'NoteEditorState(submitting: $submitting, problem: $problem, '
      'error: ${error?.code.name})';
}
