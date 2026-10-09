import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'student_summary.dart';
import 'students_filter.dart';

/// The students list's search text and halaqa chip.
class StudentsFilterController extends Notifier<StudentsFilter> {
  @override
  StudentsFilter build() => const StudentsFilter();

  void setQuery(String query) =>
      state = StudentsFilter(query: query, halaqaId: state.halaqaId);

  /// Null shows every halaqa.
  void setHalaqa(String? halaqaId) =>
      state = StudentsFilter(query: state.query, halaqaId: halaqaId);
}

final studentsFilterControllerProvider =
    NotifierProvider.autoDispose<StudentsFilterController, StudentsFilter>(
      StudentsFilterController.new,
    );

/// The students that match the filter, by studentCode.
final filteredStudentsProvider =
    Provider.autoDispose<AsyncValue<List<StudentSummary>>>((ref) {
      final filter = ref.watch(studentsFilterControllerProvider);
      return ref.watch(studentSummariesProvider).whenData(filter.apply);
    });
