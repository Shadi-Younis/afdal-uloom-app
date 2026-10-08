import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/halaqa.dart';
import '../../../core/utils/async_value_combine.dart';
import 'admin_data_providers.dart';

/// A student with their halaqa.
class StudentSummary {
  const StudentSummary({required this.student, required this.halaqa});

  final AppUser student;

  /// Null if the student's halaqa does not exist (any more).
  final Halaqa? halaqa;
}

/// Orders students by studentCode (shorter codes first, so S999 comes
/// before S1000); students without a code last.
int compareByStudentCode(AppUser a, AppUser b) {
  final ca = a.studentCode;
  final cb = b.studentCode;
  if (ca == null || cb == null) {
    return (ca == null ? 1 : 0) - (cb == null ? 1 : 0);
  }
  final byLength = ca.length.compareTo(cb.length);
  return byLength != 0 ? byLength : ca.compareTo(cb);
}

/// One summary per student, sorted by studentCode.
List<StudentSummary> summarizeStudents(
  List<AppUser> students,
  List<Halaqa> halaqat,
) {
  final halaqaById = {for (final h in halaqat) h.id: h};
  final sorted = [...students]..sort(compareByStudentCode);
  return [
    for (final s in sorted)
      StudentSummary(student: s, halaqa: halaqaById[s.halaqaId]),
  ];
}

final studentSummariesProvider =
    Provider.autoDispose<AsyncValue<List<StudentSummary>>>(
      (ref) => combine2(
        ref.watch(adminStudentsProvider),
        ref.watch(adminHalaqatProvider),
        summarizeStudents,
      ),
    );

/// The summary of one student; null when there is no such student.
final studentSummaryProvider = Provider.autoDispose
    .family<AsyncValue<StudentSummary?>, String>(
      (ref, studentId) => ref
          .watch(studentSummariesProvider)
          .whenData(
            (all) => all.where((s) => s.student.id == studentId).firstOrNull,
          ),
    );
