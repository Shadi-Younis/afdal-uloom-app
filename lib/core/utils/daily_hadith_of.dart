import '../constants/daily_hadiths.dart';
import '../models/daily_hadith.dart';

final _firstDay = DateTime.utc(
  DailyHadiths.firstDay.year,
  DailyHadiths.firstDay.month,
  DailyHadiths.firstDay.day,
);

/// The hadith of [day] (local calendar day): the one at (days since
/// DailyHadiths.firstDay) mod the list's length. The same for everyone that
/// day; the next one from local midnight. Throws [ArgumentError] for an
/// empty [hadiths].
DailyHadith dailyHadithOf(
  DateTime day, {
  List<DailyHadith> hadiths = DailyHadiths.all,
}) {
  if (hadiths.isEmpty) {
    throw ArgumentError.value(hadiths, 'hadiths', 'must not be empty');
  }
  // Calendar days in UTC: no daylight-saving hour moves a day.
  final days = DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).difference(_firstDay).inDays;
  // Dart's % is never negative for a positive divisor: days before
  // firstDay wrap around too.
  return hadiths[days % hadiths.length];
}
