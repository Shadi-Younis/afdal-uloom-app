import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/my_students_providers.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common/content_width.dart';
import '../../../core/widgets/islamic/app_card.dart';
import '../../../core/widgets/islamic/app_page_scaffold.dart';
import '../../../core/widgets/islamic/empty_state.dart';
import '../../../core/widgets/islamic/error_state.dart';
import '../../../core/widgets/islamic/loading_state.dart';
import '../application/teacher_providers.dart';
import 'widgets/teacher_recording_tile.dart';

/// «بانتظار المراجعة»: the teacher's recordings not reviewed yet, official
/// and practice, oldest first, each with its student and type. A tap
/// opens the recording (notes, «تمت المراجعة»); once reviewed it
/// leaves the list by itself.
class TeacherReviewScreen extends ConsumerWidget {
  const TeacherReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Names only: while they load, or if they fail, the list still works.
    final names = {
      for (final s in ref.watch(myStudentsProvider).value ?? const [])
        s.student.id: s.student.fullName,
    };
    return AppPageScaffold(
      title: AppStrings.pendingReview,
      body: switch (ref.watch(pendingReviewProvider)) {
        AsyncData(value: final list) when list.isEmpty => const EmptyState(
          message: AppStrings.noPendingReview,
        ),
        AsyncData(value: final list) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: ContentWidth(
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final recording in list)
                    TeacherRecordingTile(
                      recording: recording,
                      studentName: names[recording.studentId],
                    ),
                ],
              ),
            ),
          ),
        ),
        AsyncError(:final error) => ErrorState(
          error: error,
          onRetry: () => ref.invalidate(pendingReviewProvider),
        ),
        _ => const LoadingState(),
      },
    );
  }
}
