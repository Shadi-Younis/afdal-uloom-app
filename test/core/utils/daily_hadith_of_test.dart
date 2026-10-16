import 'package:afdal_uloom_tilawat/core/constants/daily_hadiths.dart';
import 'package:afdal_uloom_tilawat/core/models/daily_hadith.dart';
import 'package:afdal_uloom_tilawat/core/utils/daily_hadith_of.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Dummy entries for the rotation only: never put in DailyHadiths.
  const three = [DailyHadith('أ'), DailyHadith('ب'), DailyHadith('ج')];

  DailyHadith of(DateTime day) => dailyHadithOf(day, hadiths: three);

  test('the list is exactly the one hadith Shadi gave, letter for letter', () {
    expect(DailyHadiths.all, hasLength(1));
    final hadith = DailyHadiths.all.single;
    // The code points as Shadi gave them (with their tashkeel).
    expect(hadith.text.runes.toList(), [
      0x062E,
      0x064A,
      0x0631,
      0x064F,
      0x0643,
      0x064F,
      0x0645,
      0x0020,
      0x0645,
      0x064E,
      0x0646,
      0x0020,
      0x062A,
      0x0639,
      0x0644,
      0x064E,
      0x0651,
      0x0645,
      0x064E,
      0x0020,
      0x0627,
      0x0644,
      0x0642,
      0x0631,
      0x0622,
      0x0646,
      0x064E,
      0x0020,
      0x0648,
      0x0639,
      0x0644,
      0x064E,
      0x0651,
      0x0645,
      0x064E,
      0x0647,
      0x064F,
    ]);
    expect(hadith.source, isNull);
    expect(hadith.text, isNot(contains('«')));
    expect(hadith.text, isNot(contains('﴿')));
  });

  test('the same all day, the next one from local midnight', () {
    final morning = of(DateTime(2026, 10, 16, 0, 0, 1));
    expect(of(DateTime(2026, 10, 16, 12)), morning);
    expect(of(DateTime(2026, 10, 16, 23, 59, 59)), morning);
    final next = of(DateTime(2026, 10, 17));
    expect(next, isNot(morning));
    expect(three.indexOf(next), (three.indexOf(morning) + 1) % 3);
  });

  test('day 0 is the first; it goes round the list', () {
    expect(of(DateTime(2026, 1, 1, 9)), three[0]);
    expect(of(DateTime(2026, 1, 2)), three[1]);
    expect(of(DateTime(2026, 1, 3)), three[2]);
    expect(of(DateTime(2026, 1, 4)), three[0]);
    // Before the first day too.
    expect(of(DateTime(2025, 12, 31)), three[2]);
  });

  test('a daylight-saving night does not skip or repeat a day', () {
    // Whatever the device's zone: consecutive calendar days follow each
    // other in the list.
    for (
      var d = DateTime(2026, 3, 20);
      d.month < 5;
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      final next = DateTime(d.year, d.month, d.day + 1);
      expect(three.indexOf(of(next)), (three.indexOf(of(d)) + 1) % 3);
    }
  });

  test('with one hadith, every day shows it', () {
    expect(dailyHadithOf(DateTime(2026, 10, 16)), DailyHadiths.all.single);
    expect(dailyHadithOf(DateTime(2030, 2, 1)), DailyHadiths.all.single);
  });

  test('an empty list throws ArgumentError', () {
    expect(
      () => dailyHadithOf(DateTime(2026), hadiths: const []),
      throwsArgumentError,
    );
  });
}
