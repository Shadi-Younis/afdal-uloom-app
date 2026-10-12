import '../constants/school_calendar.dart';

/// Midnight (local time) at the start of the school week [now] is in.
DateTime startOfSchoolWeek(DateTime now) {
  final daysBack = (now.weekday - SchoolCalendar.weekStartDay) % 7;
  return DateTime(now.year, now.month, now.day - daysBack);
}
