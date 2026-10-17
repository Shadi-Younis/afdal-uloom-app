import 'package:afdal_uloom_tilawat/core/utils/ayat_problem.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allowed: nothing, a surah alone, a surah with ayat in it', () {
    expect(ayatProblemOf(null, null, null), isNull);
    expect(ayatProblemOf(2, null, null), isNull);
    expect(ayatProblemOf(2, 1, 20), isNull);
    expect(ayatProblemOf(112, 4, 4), isNull);
    expect(ayatProblemOf(2, 286, 286), isNull);
  });

  test('ayat without a surah', () {
    expect(ayatProblemOf(null, 1, 20), AyatProblem.noSurah);
    expect(ayatProblemOf(null, 1, null), AyatProblem.noSurah);
    expect(ayatProblemOf(null, null, 4), AyatProblem.noSurah);
  });

  test('only one of the two ayat', () {
    expect(ayatProblemOf(2, 1, null), AyatProblem.oneAyahMissing);
    expect(ayatProblemOf(2, null, 20), AyatProblem.oneAyahMissing);
  });

  test('from after to, or beyond the surah', () {
    expect(ayatProblemOf(2, 21, 20), AyatProblem.notInSurah);
    expect(ayatProblemOf(112, 1, 5), AyatProblem.notInSurah);
    expect(ayatProblemOf(2, 0, 3), AyatProblem.notInSurah);
  });

  test('each problem has its Arabic message', () {
    expect(AyatProblem.noSurah.message, 'اختر السورة قبل الآيات');
    expect(
      AyatProblem.oneAyahMissing.message,
      'اكتب الآيتين «من» و«إلى» أو اتركهما فارغتين',
    );
    expect(AyatProblem.notInSurah.message, 'الآيات ليست في هذه السورة');
  });
}
