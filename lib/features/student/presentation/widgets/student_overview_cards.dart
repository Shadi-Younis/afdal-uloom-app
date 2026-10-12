import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/islamic/error_state.dart';
import '../../../../core/widgets/islamic/loading_state.dart';
import '../../../../core/widgets/islamic/stat_card.dart';
import '../../application/student_providers.dart';

/// The student's three counts: «تسجيلاتي», «ملاحظات جديدة» and
/// «تدريباتي هذا الأسبوع». A label may take two lines on a phone.
class StudentOverviewCards extends ConsumerWidget {
  const StudentOverviewCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(studentOverviewProvider)) {
      // One height for the three cards, also when a label takes two lines.
      AsyncData(value: final overview) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: StatCard(
                number: overview.recordings,
                label: AppStrings.myRecordings,
              ),
            ),
            const SizedBox(width: AppSizes.spaceS),
            Expanded(
              child: StatCard(
                number: overview.newNotes,
                label: AppStrings.newNotes,
              ),
            ),
            const SizedBox(width: AppSizes.spaceS),
            Expanded(
              child: StatCard(
                number: overview.practiceThisWeek,
                label: AppStrings.myPracticeThisWeek,
              ),
            ),
          ],
        ),
      ),
      AsyncError(:final error) => ErrorState(
        error: error,
        onRetry: () => ref.invalidate(myRecordingsProvider),
      ),
      _ => const LoadingState(),
    };
  }
}
