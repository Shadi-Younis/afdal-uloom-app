import '../models/daily_hadith.dart';

// «حديث اليوم» on the student, teacher and admin homes. The texts come ONLY
// from Shadi: nobody else adds, writes, translates, corrects or completes a
// hadith or its source here.
//
// To add one, put a line at the end of the list, with its tashkeel and
// without quotation marks (the card adds « »), and its source if Shadi
// gives one:
//
//   DailyHadith('...'),
//   DailyHadith('...', '...'),
//
// Each day shows the next one (dailyHadithOf in core/utils), the same for
// everyone, changing at local midnight.

/// The hadiths of «حديث اليوم», in the order the days show them.
abstract final class DailyHadiths {
  static const all = [DailyHadith('خيرُكُم مَن تعلَّمَ القرآنَ وعلَّمَهُ')];

  /// The day the list starts from: day 0 shows its first hadith.
  static const firstDay = (year: 2026, month: 1, day: 1);
}
