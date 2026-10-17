import '../../../core/errors/app_exception.dart';
import '../../../core/utils/ayat_problem.dart';

/// The state of «تعديل السورة والآيات»: sending, a problem with the
/// choice, or a failure from the server.
class AyatEditorState {
  const AyatEditorState({this.submitting = false, this.problem, this.error});

  final bool submitting;
  final AyatProblem? problem;
  final AppException? error;

  @override
  bool operator ==(Object other) =>
      other is AyatEditorState &&
      other.submitting == submitting &&
      other.problem == problem &&
      other.error?.code == error?.code;

  @override
  int get hashCode => Object.hash(submitting, problem, error?.code);

  @override
  String toString() =>
      'AyatEditorState(submitting: $submitting, problem: $problem, '
      'error: ${error?.code.name})';
}
