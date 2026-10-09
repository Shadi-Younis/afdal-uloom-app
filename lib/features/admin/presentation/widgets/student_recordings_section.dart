import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/islamic/error_state.dart';
import '../../../../core/widgets/islamic/loading_state.dart';
import '../../../../core/widgets/common/recording_tile.dart';
import '../../application/admin_data_providers.dart';
import 'section_card.dart';

/// The student's recordings, newest first; a tap opens the recording.
class StudentRecordingsSection extends ConsumerWidget {
  const StudentRecordingsSection({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordings = ref.watch(studentRecordingsProvider(studentId));
    return SectionCard(
      title: AppStrings.recordingsTitle,
      child: switch (recordings) {
        AsyncData(value: final list) when list.isEmpty => const Text(
          AppStrings.noRecordings,
        ),
        AsyncData(value: final list) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final recording in list)
              RecordingTile(
                recording: recording,
                // push: back returns to this student.
                onTap: () => context.push(AppRoutes.recording(recording.id)),
              ),
          ],
        ),
        AsyncError(:final error) => ErrorState(
          error: error,
          onRetry: () => ref.invalidate(studentRecordingsProvider(studentId)),
        ),
        _ => const LoadingState(),
      },
    );
  }
}
