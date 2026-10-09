import '../../../core/utils/arabic_search.dart';
import 'student_summary.dart';

/// What the students list is narrowed to: a search on name or code, and
/// optionally one halaqa.
class StudentsFilter {
  const StudentsFilter({this.query = '', this.halaqaId});

  final String query;

  /// Null: every halaqa.
  final String? halaqaId;

  /// Keeps the order of [students].
  List<StudentSummary> apply(List<StudentSummary> students) => [
    for (final s in students)
      if ((halaqaId == null || s.student.halaqaId == halaqaId) &&
          (matchesSearch(s.student.fullName, query) ||
              matchesSearch(s.student.studentCode ?? '', query)))
        s,
  ];

  @override
  bool operator ==(Object other) =>
      other is StudentsFilter &&
      other.query == query &&
      other.halaqaId == halaqaId;

  @override
  int get hashCode => Object.hash(query, halaqaId);

  @override
  String toString() => 'StudentsFilter(query: $query, halaqaId: $halaqaId)';
}
