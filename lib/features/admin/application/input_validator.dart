import '../../../core/constants/model_limits.dart';
import 'input_error.dart';

final _username = RegExp(ModelLimits.usernamePattern);
final _studentCode = RegExp(ModelLimits.studentCodePattern);

/// The checks the account functions and the halaqat rules apply, run before
/// calling them so the admin gets an error next to the field at once.
abstract final class InputValidator {
  static InputError? fullName(String value) => _length(
    value.trim(),
    ModelLimits.fullNameMinLength,
    ModelLimits.fullNameMaxLength,
  );

  /// Checks [username] as the server will store it (see [normalizeUsername]).
  static InputError? username(String value) {
    final username = normalizeUsername(value);
    return _length(
          username,
          ModelLimits.usernameMinLength,
          ModelLimits.usernameMaxLength,
        ) ??
        (_username.hasMatch(username) ? null : InputError.invalidCharacters);
  }

  /// Not trimmed: spaces are part of a password.
  static InputError? password(String value) => _length(
    value,
    ModelLimits.passwordMinLength,
    ModelLimits.passwordMaxLength,
  );

  /// Checks [value] after [normalizeStudentCode].
  static InputError? studentCode(String value) {
    final code = normalizeStudentCode(value);
    if (code.isEmpty) return InputError.required;
    return _studentCode.hasMatch(code) ? null : InputError.invalidFormat;
  }

  static InputError? halaqaName(String value) => _length(
    value.trim(),
    ModelLimits.halaqaNameMinLength,
    ModelLimits.halaqaNameMaxLength,
  );

  /// For pickers: a choice is required.
  static InputError? choice(String? id) =>
      id == null || id.isEmpty ? InputError.required : null;

  /// What the server does to a username before using it.
  static String normalizeUsername(String value) => value.trim().toLowerCase();

  /// Codes are upper-case; `s014` typed by hand becomes `S014`.
  static String normalizeStudentCode(String value) =>
      value.trim().toUpperCase();

  static InputError? _length(String value, int min, int max) {
    if (value.isEmpty) return InputError.required;
    if (value.length < min) return InputError.tooShort;
    if (value.length > max) return InputError.tooLong;
    return null;
  }
}
