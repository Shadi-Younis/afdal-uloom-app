import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/islamic/app_page_scaffold.dart';
import '../../../core/widgets/islamic/error_state.dart';
import '../../../core/widgets/islamic/loading_state.dart';
import '../application/recording_details_providers.dart';
import 'widgets/recording_details_view.dart';

/// One recording, for every role: the surah in its cartouche, ayat, type,
/// date, uploader, the player and the teacher's notes. Another student's
/// recording shows the permission error (the rules refuse it).
class RecordingScreen extends ConsumerWidget {
  const RecordingScreen({super.key, required this.recordingId});

  final String recordingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recording = ref.watch(recordingDetailsProvider(recordingId));
    final studentId = recording.value?.studentId;
    final student = studentId == null
        ? null
        : ref
              .watch(
                personNameProvider((
                  uid: studentId,
                  fallback: '',
                  missing: null,
                )),
              )
              .value;
    return AppPageScaffold(
      title: student == null || student.isEmpty
          ? AppStrings.recordingScreenTitle
          : AppStrings.recordingOf(student),
      body: switch (recording) {
        AsyncData(value: final recording?) => RecordingDetailsView(
          recording: recording,
        ),
        AsyncData() => const ErrorState(
          error: AppException(AppErrorCode.notFound),
        ),
        AsyncError(:final error) => ErrorState(
          error: error,
          onRetry: () => ref.invalidate(recordingDetailsProvider(recordingId)),
        ),
        _ => const LoadingState(),
      },
    );
  }
}
