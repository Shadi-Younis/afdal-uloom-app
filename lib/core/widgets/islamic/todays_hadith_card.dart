import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/daily_hadith_provider.dart';
import 'daily_hadith_card.dart';

/// Today's «حديث اليوم» (dailyHadithProvider), for the three homes.
class TodaysHadithCard extends ConsumerWidget {
  const TodaysHadithCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      DailyHadithCard(hadith: ref.watch(dailyHadithProvider));
}
