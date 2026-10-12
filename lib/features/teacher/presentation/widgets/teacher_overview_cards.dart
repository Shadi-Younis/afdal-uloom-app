import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/islamic/error_state.dart';
import '../../../../core/widgets/islamic/loading_state.dart';
import '../../../../core/widgets/islamic/stat_card.dart';
import '../../application/teacher_providers.dart';

/// The teacher's three counts: «طلابي», «تسجيلات هذا الأسبوع» and
/// «بانتظار المراجعة».
class TeacherOverviewCards extends ConsumerWidget {
  const TeacherOverviewCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(teacherOverviewProvider)) {
      // One height for the three cards, also when a label takes two lines.
      AsyncData(value: final overview) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: StatCard(
                number: overview.students,
                label: AppStrings.myStudents,
              ),
            ),
            const SizedBox(width: AppSizes.spaceS),
            Expanded(
              child: StatCard(
                number: overview.thisWeek,
                label: AppStrings.thisWeekRecordings,
              ),
            ),
            const SizedBox(width: AppSizes.spaceS),
            Expanded(
              child: StatCard(
                number: overview.pendingReview,
                label: AppStrings.pendingReview,
              ),
            ),
          ],
        ),
      ),
      AsyncError(:final error) => ErrorState(
        error: error,
        onRetry: () => ref
          ..invalidate(thisWeekRecordingsProvider)
          ..invalidate(pendingReviewProvider),
      ),
      _ => const LoadingState(),
    };
  }
}
