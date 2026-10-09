import 'package:hijri/hijri_calendar.dart';

import '../constants/app_strings.dart';
import 'arabic_digits.dart';

/// [date]'s day in the Hijri calendar (Umm al-Qura, as in Saudi Arabia)
/// with the weekday: "٢٧ ربيع الآخر ١٤٤٨ هـ · الجمعة". The civil day is
/// used (the Hijri day really starts at sunset).
String formatHijriDate(DateTime date) {
  final hijri = HijriCalendar.fromDate(date);
  return '${toArabicDigits(hijri.hDay)} '
      '${AppStrings.hijriMonths[hijri.hMonth - 1]} '
      '${toArabicDigits(hijri.hYear)} ${AppStrings.hijriEra}'
      '${AppStrings.detailSeparator}'
      '${AppStrings.weekdays[date.weekday - 1]}';
}
