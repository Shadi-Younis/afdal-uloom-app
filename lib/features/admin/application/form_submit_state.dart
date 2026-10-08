import 'package:flutter/foundation.dart' show mapEquals;

import '../../../core/errors/app_exception.dart';
import 'input_error.dart';
import 'input_field.dart';

/// The state of an admin form: errors per field, whether it is being sent,
/// and a failure that belongs to no field (network, permission, ...).
class FormSubmitState {
  const FormSubmitState({
    this.fieldErrors = const {},
    this.submitting = false,
    this.error,
  });

  /// A server failure: a taken username or student code goes next to its
  /// field, anything else is the form's [error].
  factory FormSubmitState.failed(AppException error) => switch (error.code) {
    AppErrorCode.usernameTaken => const FormSubmitState(
      fieldErrors: {InputField.username: InputError.taken},
    ),
    AppErrorCode.studentCodeTaken => const FormSubmitState(
      fieldErrors: {InputField.studentCode: InputError.taken},
    ),
    _ => FormSubmitState(error: error),
  };

  final Map<InputField, InputError> fieldErrors;
  final bool submitting;
  final AppException? error;

  InputError? errorOf(InputField field) => fieldErrors[field];

  /// After the admin edits [field]: its error and the form's error go.
  FormSubmitState edited(InputField field) => FormSubmitState(
    fieldErrors: {...fieldErrors}..remove(field),
    submitting: submitting,
  );

  @override
  bool operator ==(Object other) =>
      other is FormSubmitState &&
      mapEquals(other.fieldErrors, fieldErrors) &&
      other.submitting == submitting &&
      other.error?.code == error?.code;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(fieldErrors.entries.map((e) => (e.key, e.value))),
    submitting,
    error?.code,
  );

  @override
  String toString() =>
      'FormSubmitState(fieldErrors: $fieldErrors, submitting: $submitting, '
      'error: ${error?.code.name})';
}
