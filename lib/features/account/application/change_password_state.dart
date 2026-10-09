import 'package:flutter/foundation.dart' show mapEquals;

import '../../../core/errors/app_exception.dart';

/// The three fields of the change-password form.
enum PasswordInput { current, next, confirm }

/// Why a field was refused, before or by Firebase.
enum PasswordProblem {
  required,

  /// Outside ModelLimits.passwordMinLength..passwordMaxLength.
  length,

  /// The confirmation differs from the new password.
  mismatch,

  /// The current password is wrong.
  wrong,

  /// Firebase finds the new password too weak.
  weak,
}

/// The state of the change-password form: a problem per field, whether it
/// is being sent, and a failure that belongs to no field.
class ChangePasswordState {
  const ChangePasswordState({
    this.problems = const {},
    this.submitting = false,
    this.error,
  });

  /// A failure from AuthService: a wrong current password or a weak new one
  /// goes next to its field, anything else is the form's [error].
  factory ChangePasswordState.failed(AppException error) =>
      switch (error.code) {
        AppErrorCode.wrongPassword => const ChangePasswordState(
          problems: {PasswordInput.current: PasswordProblem.wrong},
        ),
        AppErrorCode.weakPassword => const ChangePasswordState(
          problems: {PasswordInput.next: PasswordProblem.weak},
        ),
        _ => ChangePasswordState(error: error),
      };

  final Map<PasswordInput, PasswordProblem> problems;
  final bool submitting;
  final AppException? error;

  PasswordProblem? problemOf(PasswordInput input) => problems[input];

  /// After the user edits [input]: its problem and the form's error go.
  ChangePasswordState edited(PasswordInput input) => ChangePasswordState(
    problems: {...problems}..remove(input),
    submitting: submitting,
  );

  @override
  bool operator ==(Object other) =>
      other is ChangePasswordState &&
      mapEquals(other.problems, problems) &&
      other.submitting == submitting &&
      other.error?.code == error?.code;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(problems.entries.map((e) => (e.key, e.value))),
    submitting,
    error?.code,
  );

  @override
  String toString() =>
      'ChangePasswordState(problems: $problems, submitting: $submitting, '
      'error: ${error?.code.name})';
}
