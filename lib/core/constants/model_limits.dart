/// Validation limits of the data model and of account input. firestore.rules
/// and functions/src/lib/constants.ts enforce the same numbers; change them
/// together.
abstract final class ModelLimits {
  static const surahMin = 1;
  static const surahMax = 114;
  static const ayahMin = 1;
  static const ratingMin = 1;
  static const ratingMax = 5;
  static const halaqaNameMinLength = 1;
  static const halaqaNameMaxLength = 60;
  static const noteMaxLength = 2000;

  /// Ten hours: far longer than any recitation.
  static const atSecondMax = 36000;

  // Accounts (createUser / resetPassword).
  static const fullNameMinLength = 2;
  static const fullNameMaxLength = 60;
  static const usernameMinLength = 3;
  static const usernameMaxLength = 20;

  /// Allowed username characters, after trimming and lower-casing.
  static const usernamePattern = r'^[a-z0-9._-]+$';
  static const passwordMinLength = 6;
  static const passwordMaxLength = 64;

  /// What the server accepts: `S` + 3..5 digits, e.g. `S023`.
  static const studentCodePattern = r'^S\d{3,5}$';
  static const studentCodePrefix = 'S';

  /// The app hands out S + 3 digits: S001..S999.
  static const studentCodeDigits = 3;
  static const studentCodeMaxNumber = 999;

  // Generated passwords: easy to read aloud and type. No 0, 1 or the
  // letters o, i, l, which look alike in many fonts.
  static const generatedPasswordLength = 8;
  static const generatedPasswordMinDigits = 2;
  static const generatedPasswordLetters = 'abcdefghjkmnpqrstuvwxyz';
  static const generatedPasswordDigits = '23456789';
}
