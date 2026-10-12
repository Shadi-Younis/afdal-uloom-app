import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/my_students_providers.dart';
import '../../../core/application/session_providers.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/halaqa.dart';
import '../../../core/models/recording.dart';
import '../../../core/models/recording_type.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/async_value_combine.dart';
import '../../../core/utils/school_week.dart';
import 'teacher_overview.dart';

/// The signed-in teacher's uid ('' while signed out: every query below
/// then asks for nothing that exists).
String _uid(Ref ref) =>
    ref.watch(sessionProvider.select((s) => s.value?.uid)) ?? '';

/// The teacher's recordings recorded since the start of the school week,
/// newest first.
final thisWeekRecordingsProvider = StreamProvider.autoDispose<List<Recording>>(
  (ref) => ref
      .watch(recordingRepositoryProvider)
      .watchForTeacherSince(
        _uid(ref),
        startOfSchoolWeek(ref.watch(clockProvider)()),
      ),
);

/// Official recordings of the teacher not reviewed yet, oldest first.
final pendingReviewProvider = StreamProvider.autoDispose<List<Recording>>(
  (ref) => ref
      .watch(recordingRepositoryProvider)
      .watchUnreviewed(_uid(ref), type: RecordingType.official),
);

/// The counts of the teacher's home.
final teacherOverviewProvider =
    Provider.autoDispose<AsyncValue<TeacherOverview>>(
      (ref) => combine3(
        ref.watch(myStudentsProvider),
        ref.watch(thisWeekRecordingsProvider),
        ref.watch(pendingReviewProvider),
        (students, week, pending) => TeacherOverview(
          students: students.where((s) => !s.student.disabled).length,
          thisWeek: week.length,
          pendingReview: pending.length,
        ),
      ),
    );

/// Halaqa [halaqaId], or null when it does not exist.
final teacherHalaqaProvider = StreamProvider.autoDispose
    .family<Halaqa?, String>(
      (ref, halaqaId) => ref.watch(halaqaRepositoryProvider).watch(halaqaId),
    );

/// Student [studentId]'s profile, or null when it does not exist.
final teacherStudentProvider = StreamProvider.autoDispose
    .family<AppUser?, String>(
      (ref, studentId) =>
          ref.watch(userRepositoryProvider).watchUser(studentId),
    );

/// Student [studentId]'s recordings of this teacher, newest first.
final teacherStudentRecordingsProvider = StreamProvider.autoDispose
    .family<List<Recording>, String>(
      (ref, studentId) => ref
          .watch(recordingRepositoryProvider)
          .watchForStudent(studentId, teacherId: _uid(ref)),
    );
