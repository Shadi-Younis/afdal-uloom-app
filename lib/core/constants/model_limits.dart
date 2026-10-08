/// Validation limits of the data model. firestore.rules enforces the same
/// numbers; change both together.
abstract final class ModelLimits {
  static const surahMin = 1;
  static const surahMax = 114;
  static const ayahMin = 1;
  static const ratingMin = 1;
  static const ratingMax = 5;
  static const halaqaNameMaxLength = 60;
  static const noteMaxLength = 2000;

  /// Ten hours: far longer than any recitation.
  static const atSecondMax = 36000;
}
