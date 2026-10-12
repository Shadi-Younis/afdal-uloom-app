import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/islamic/app_card.dart';
import '../../../../core/widgets/islamic/empty_state.dart';
import '../../../../core/widgets/islamic/error_state.dart';
import '../../../../core/widgets/islamic/loading_state.dart';
import '../../application/teacher_providers.dart';
import 'teacher_recording_tile.dart';

/// The student's recordings of this teacher, newest first, in one card.
class TeacherStudentRecordings extends ConsumerWidget {
  const TeacherStudentRecordings({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(teacherStudentRecordingsProvider(studentId))) {
      AsyncData(value: final list) when list.isEmpty => const EmptyState(
        message: AppStrings.noRecordings,
      ),
      AsyncData(value: final list) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final recording in list)
              TeacherRecordingTile(recording: recording),
          ],
        ),
      ),
      AsyncError(:final error) => ErrorState(
        error: error,
        onRetry: () =>
            ref.invalidate(teacherStudentRecordingsProvider(studentId)),
      ),
      _ => const LoadingState(),
    };
  }
}
