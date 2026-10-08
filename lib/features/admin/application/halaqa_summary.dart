import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/halaqa.dart';
import '../../../core/utils/async_value_combine.dart';
import 'admin_data_providers.dart';
import 'student_summary.dart';

/// A halaqa with its teacher and students, as the admin screens show it.
class HalaqaSummary {
  const HalaqaSummary({
    required this.halaqa,
    required this.teacher,
    required this.students,
  });

  final Halaqa halaqa;

  /// Null if the teacher's profile is missing.
  final AppUser? teacher;

  /// Every student of the halaqa, disabled ones included, by studentCode.
  final List<AppUser> students;

  /// What the lists show as the halaqa's size: students who left (disabled)
  /// do not count.
  int get activeStudentCount => students.where((s) => !s.disabled).length;
}

/// One summary per halaqa, in the order of [halaqat].
List<HalaqaSummary> summarizeHalaqat(
  List<Halaqa> halaqat,
  List<AppUser> teachers,
  List<AppUser> students,
) {
  final teacherById = {for (final t in teachers) t.id: t};
  final sorted = [...students]..sort(compareByStudentCode);
  return [
    for (final halaqa in halaqat)
      HalaqaSummary(
        halaqa: halaqa,
        teacher: teacherById[halaqa.teacherId],
        students: [...sorted.where((s) => s.halaqaId == halaqa.id)],
      ),
  ];
}

final halaqaSummariesProvider =
    Provider.autoDispose<AsyncValue<List<HalaqaSummary>>>(
      (ref) => combine3(
        ref.watch(adminHalaqatProvider),
        ref.watch(adminTeachersProvider),
        ref.watch(adminStudentsProvider),
        summarizeHalaqat,
      ),
    );

/// The summary of one halaqa; null when it does not exist.
final halaqaSummaryProvider = Provider.autoDispose
    .family<AsyncValue<HalaqaSummary?>, String>(
      (ref, halaqaId) => ref
          .watch(halaqaSummariesProvider)
          .whenData(
            (all) => all.where((s) => s.halaqa.id == halaqaId).firstOrNull,
          ),
    );
