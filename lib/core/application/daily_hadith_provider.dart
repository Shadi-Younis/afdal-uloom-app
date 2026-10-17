import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_hadith.dart';
import '../providers/clock_provider.dart';
import '../utils/daily_hadith_of.dart';

/// «حديث اليوم» for today; a home left open over local midnight shows the
/// next day's.
final dailyHadithProvider = Provider.autoDispose<DailyHadith>((ref) {
  final now = ref.watch(clockProvider)();
  final midnight = DateTime(now.year, now.month, now.day + 1);
  final timer = Timer(midnight.difference(now), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return dailyHadithOf(now);
});
