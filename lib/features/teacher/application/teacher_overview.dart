/// The three counts of the teacher's home.
class TeacherOverview {
  const TeacherOverview({
    required this.students,
    required this.thisWeek,
    required this.pendingReview,
  });

  /// Active students in the teacher's halaqat («طلابي»).
  final int students;

  /// Official recordings of the teacher's students recorded since the
  /// start of the school week («تسجيلات هذا الأسبوع»).
  final int thisWeek;

  /// Official recordings whose voice markers the teacher has not reviewed
  /// yet («بانتظار المراجعة»).
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
