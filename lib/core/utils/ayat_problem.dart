import '../constants/app_strings.dart';
import '../constants/surahs.dart';

/// Why a surah and ayat choice cannot be saved. Allowed are: nothing, a
/// surah alone, or a surah with both ayat, existing in it (an official
/// recording; a practice needs all three, see isValidAyahRange).
enum AyatProblem {
  /// Ayat without a surah.
  noSurah,

  /// Only one of «من آية» and «إلى آية».
  oneAyahMissing,

  /// Not in the surah, or «من» after «إلى».
  notInSurah;

  /// The Arabic message shown under the ayat.
  String get message => switch (this) {
    noSurah => AppStrings.ayatNeedSurah,
    oneAyahMissing => AppStrings.ayatBothOrNone,
    notInSurah => AppStrings.ayatNotInSurah,
  };
}

/// What is wrong with [surah], [from] and [to]; null when they may be
/// saved (also when all three are empty).
AyatProblem? ayatProblemOf(int? surah, int? from, int? to) =>
    switch ((surah, from, to)) {
      (_, null, null) => null,
      (null, _, _) => AyatProblem.noSurah,
      (final s?, final f?, final t?) =>
        isValidAyahRange(s, f, t) ? null : AyatProblem.notInSurah,
      _ => AyatProblem.oneAyahMissing,
    };
