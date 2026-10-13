import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/islamic/empty_state.dart';
import '../../../../core/widgets/islamic/error_state.dart';
import '../../../../core/widgets/islamic/loading_state.dart';
import '../../application/student_providers.dart';
import 'student_recording_card.dart';

/// The student's recordings through the selected chip, newest first, live.
/// Empty: what will appear here; empty only for the chip: that no
/// recording is of this type.
class StudentRecordingsList extends ConsumerWidget {
  const StudentRecordingsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAny = ref.watch(myRecordingsProvider).value?.isNotEmpty ?? false;
    return switch (ref.watch(filteredRecordingsProvider)) {
      AsyncData(value: final list) when list.isEmpty => EmptyState(
        message: hasAny
            ? AppStrings.noRecordingsOfType
            : AppStrings.noStudentRecordings,
      ),
      AsyncData(value: final list) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final recording in list)
            StudentRecordingCard(
              key: ValueKey(recording.id),
              recording: recording,
            ),
        ],
      ),
      AsyncError(:final error) => ErrorState(
        error: error,
        onRetry: () => ref.invalidate(myRecordingsProvider),
      ),
      _ => const LoadingState(),
    };
  }
}
