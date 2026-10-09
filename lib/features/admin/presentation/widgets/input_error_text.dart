import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/model_limits.dart';
import '../../application/form_submit_state.dart';
import '../../application/input_error.dart';
import '../../application/input_field.dart';

/// The Arabic error to show under [field], or null when it has none.
String? inputErrorText(FormSubmitState state, InputField field) {
  final error = state.errorOf(field);
  if (error == null) return null;
  return switch ((field, error)) {
    (InputField.studentCode, InputError.taken) =>
      AppStrings.errorStudentCodeTaken,
    (_, InputError.taken) => AppStrings.errorUsernameTaken,
    (InputField.fullName, InputError.required) => AppStrings.fullNameRequired,
    (InputField.fullName, _) => AppStrings.fullNameLength(
      ModelLimits.fullNameMinLength,
      ModelLimits.fullNameMaxLength,
    ),
    (InputField.username, InputError.required) => AppStrings.usernameRequired,
    (InputField.username, InputError.invalidCharacters) =>
      AppStrings.usernameInvalid,
    (InputField.username, _) => AppStrings.usernameLength(
      ModelLimits.usernameMinLength,
      ModelLimits.usernameMaxLength,
    ),
    (InputField.password, InputError.required) => AppStrings.passwordRequired,
    (InputField.password, _) => AppStrings.passwordLength(
      ModelLimits.passwordMinLength,
      ModelLimits.passwordMaxLength,
    ),
    (InputField.studentCode, InputError.required) =>
      AppStrings.studentCodeRequired,
    (InputField.studentCode, _) => AppStrings.studentCodeInvalid,
    (InputField.halaqa, _) => AppStrings.halaqaRequired,
    (InputField.halaqaName, InputError.required) =>
      AppStrings.halaqaNameRequired,
    (InputField.halaqaName, _) => AppStrings.halaqaNameTooLong(
      ModelLimits.halaqaNameMaxLength,
    ),
    (InputField.teacher, _) => AppStrings.teacherRequired,
  };
}
