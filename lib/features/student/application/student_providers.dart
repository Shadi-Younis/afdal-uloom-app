import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/session_providers.dart';
import '../../../core/models/recording.dart';
import '../../../core/models/recording_type.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/school_week.dart';
import 'recordings_filter_controller.dart';
import 'student_overview.dart';

/// The signed-in student's recordings, official and practice, newest
/// first, live ('' while signed out asks for nothing that exists).
///
/// A two-file recording appears once the server joined its files
/// (Recording.hasAudio): before that there is nothing to hear, and the
/// student never sees that the studio sent two files.
final myRecordingsProvider = StreamProvider.autoDispose<List<Recording>>((ref) {
  final uid = ref.watch(sessionProvider.select((s) => s.value?.uid)) ?? '';
  return ref
      .watch(recordingRepositoryProvider)
      .watchForStudent(uid)
      .map((list) => [...list.where((recording) => recording.hasAudio)]);
});

/// The counts of the student's home, from [myRecordingsProvider].
final studentOverviewProvider =
    Provider.autoDispose<AsyncValue<StudentOverview>>((ref) {
      final weekStart = startOfSchoolWeek(ref.watch(clockProvider)());
      return ref
          .watch(myRecordingsProvider)
          .whenData(
            (list) => StudentOverview(
              recordings: list.length,
              newNotes: list.where((r) => r.unreadFeedback).length,
              practiceThisWeek: list
                  .where(
                    (r) =>
                        r.type == RecordingType.practice &&
                        !r.recordedAt.isBefore(weekStart),
                  )
                  .length,
            ),
          );
    });

/// [myRecordingsProvider] through the selected chip.
final filteredRecordingsProvider =
    Provider.autoDispose<AsyncValue<List<Recording>>>((ref) {
      final filter = ref.watch(recordingsFilterProvider);
      return ref
          .watch(myRecordingsProvider)
          .whenData((list) => [...list.where(filter.matches)]);
    });
