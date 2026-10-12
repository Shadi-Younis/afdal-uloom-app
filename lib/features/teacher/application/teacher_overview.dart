/// The three counts of the teacher's home.
class TeacherOverview {
  const TeacherOverview({
    required this.students,
    required this.thisWeek,
    required this.pendingReview,
  });

  /// Active students in the teacher's halaqat («طلابي»).
  final int students;

  /// Recordings of the teacher's students recorded since the start of the
  /// school week («تسجيلات هذا الأسبوع»).
  final int thisWeek;

  /// Recordings the teacher has not reviewed yet («بانتظار المراجعة»):
  /// official ones (their voice markers) and practice ones.
  final int pendingReview;

  @override
  bool operator ==(Object other) =>
      other is TeacherOverview &&
      other.students == students &&
      other.thisWeek == thisWeek &&
      other.pendingReview == pendingReview;

  @override
  int get hashCode => Object.hash(students, thisWeek, pendingReview);

  @override
  String toString() =>
      'TeacherOverview(students: $students, thisWeek: $thisWeek, '
      'pendingReview: $pendingReview)';
}
