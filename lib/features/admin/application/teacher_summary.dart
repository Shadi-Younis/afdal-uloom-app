import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/session_providers.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/halaqa.dart';
import '../../../core/utils/async_value_combine.dart';
import 'admin_data_providers.dart';

/// A teacher with the halaqat they teach.
class TeacherSummary {
  const TeacherSummary({required this.teacher, required this.halaqat});

  final AppUser teacher;
  final List<Halaqa> halaqat;
}

/// One summary per teacher, in the order of [teachers].
List<TeacherSummary> summarizeTeachers(
  List<AppUser> teachers,
  List<Halaqa> halaqat,
) => [
  for (final teacher in teachers)
    TeacherSummary(
      teacher: teacher,
      halaqat: [...halaqat.where((h) => h.teacherId == teacher.id)],
    ),
];

final teacherSummariesProvider =
    Provider.autoDispose<AsyncValue<List<TeacherSummary>>>(
      (ref) => combine2(
        ref.watch(adminTeachersProvider),
        ref.watch(adminHalaqatProvider),
        summarizeTeachers,
      ),
    );

/// The summary of one teacher; null when there is no such teacher.
final teacherSummaryProvider = Provider.autoDispose
    .family<AsyncValue<TeacherSummary?>, String>(
      (ref, teacherId) => ref
          .watch(teacherSummariesProvider)
          .whenData(
            (all) => all.where((s) => s.teacher.id == teacherId).firstOrNull,
          ),
    );

/// Whether the signed-in admin may disable [uid]: never their own account
/// (setUserDisabled refuses it too).
final canDisableProvider = Provider.autoDispose.family<bool, String>(
  (ref, uid) => ref.watch(sessionProvider.select((s) => s.value?.uid)) != uid,
);
