import 'package:afdal_uloom_tilawat/core/constants/surahs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('114 surahs, numbered 1..114 in order', () {
    expect(surahs, hasLength(114));
    for (var i = 0; i < surahs.length; i++) {
      expect(surahs[i].number, i + 1);
    }
  });

  test('6236 ayat in total (Hafs)', () {
    expect(surahs.fold<int>(0, (sum, s) => sum + s.ayahCount), 6236);
  });

  test('spot checks of ayah counts', () {
    const expected = {
      1: 7,
      2: 286,
      9: 129,
      18: 110,
      36: 83,
      67: 30,
      112: 4,
      114: 6,
    };
    for (final MapEntry(key: number, value: count) in expected.entries) {
      expect(surahByNumber(number).ayahCount, count, reason: 'surah $number');
    }
  });

  test('names: first, last, and every one non-empty and unique', () {
    expect(surahByNumber(1).nameAr, 'الفاتحة');
    expect(surahByNumber(2).nameAr, 'البقرة');
    expect(surahByNumber(114).nameAr, 'الناس');
    expect(surahs.every((s) => s.nameAr.trim().isNotEmpty), isTrue);
    expect(surahs.map((s) => s.nameAr).toSet(), hasLength(114));
  });

  test('surahByNumber rejects numbers outside 1..114', () {
    expect(() => surahByNumber(0), throwsRangeError);
    expect(() => surahByNumber(115), throwsRangeError);
  });

  group('isValidAyahRange', () {
    test('accepts ranges inside the surah', () {
      expect(isValidAyahRange(1, 1, 7), isTrue);
      expect(isValidAyahRange(2, 255, 257), isTrue);
      expect(isValidAyahRange(114, 6, 6), isTrue);
    });

    test('rejects a bad surah, a reversed range or ayat past the end', () {
      expect(isValidAyahRange(0, 1, 1), isFalse);
      expect(isValidAyahRange(115, 1, 1), isFalse);
      expect(isValidAyahRange(1, 0, 3), isFalse);
      expect(isValidAyahRange(1, 5, 4), isFalse);
      expect(isValidAyahRange(1, 1, 8), isFalse);
      expect(isValidAyahRange(2, 286, 287), isFalse);
    });
  });

  group('formatRecordingTitle', () {
    test('a range, in Arabic-Indic digits', () {
      expect(formatRecordingTitle(2, 1, 20), 'البقرة: الآيات ١–٢٠');
      expect(formatRecordingTitle(2, 255, 257), 'البقرة: الآيات ٢٥٥–٢٥٧');
    });

    test('a single ayah', () {
      expect(formatRecordingTitle(2, 5, 5), 'البقرة: الآية ٥');
    });

    test('rejects a bad surah', () {
      expect(() => formatRecordingTitle(0, 1, 1), throwsRangeError);
    });
  });

  test('formatAyahRange: the ayat alone', () {
    expect(formatAyahRange(1, 20), 'الآيات ١–٢٠');
    expect(formatAyahRange(5, 5), 'الآية ٥');
  });
}
