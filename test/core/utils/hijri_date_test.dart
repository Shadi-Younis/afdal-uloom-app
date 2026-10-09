import 'package:afdal_uloom_tilawat/core/utils/hijri_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Umm al-Qura dates.
  final known = {
    DateTime(2026, 2, 18): '١ رمضان ١٤٤٧ هـ · الأربعاء',
    DateTime(2026, 3, 20): '١ شوال ١٤٤٧ هـ · الجمعة',
    DateTime(2026, 5, 27): '١٠ ذو الحجة ١٤٤٧ هـ · الأربعاء',
    DateTime(2026, 6, 16): '١ محرم ١٤٤٨ هـ · الثلاثاء',
    DateTime(2026, 10, 9): '٢٨ ربيع الآخر ١٤٤٨ هـ · الجمعة',
  };
  for (final MapEntry(key: date, value: text) in known.entries) {
    test('$date -> $text', () => expect(formatHijriDate(date), text));
  }

  test('the time of day does not matter', () {
    expect(
      formatHijriDate(DateTime(2026, 6, 16, 23, 59)),
      formatHijriDate(DateTime(2026, 6, 16)),
    );
  });
}
