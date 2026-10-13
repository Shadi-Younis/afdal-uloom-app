/// The three counts of the student's home.
class StudentOverview {
  const StudentOverview({
    required this.recordings,
    required this.newNotes,
    required this.practiceThisWeek,
  });

  /// All his recordings, official and practice («تسجيلاتي»).
  final int recordings;

  /// Recordings with notes he has not read yet («ملاحظات جديدة»).
  final int newNotes;

  /// Practice recordings since the start of the school week, Saturday
  /// («تدريباتي هذا الأسبوع»).
  final int practiceThisWeek;

  @override
  bool operator ==(Object other) =>
      other is StudentOverview &&
      other.recordings == recordings &&
      other.newNotes == newNotes &&
      other.practiceThisWeek == practiceThisWeek;

  @override
  int get hashCode => Object.hash(recordings, newNotes, practiceThisWeek);

  @override
  String toString() =>
      'StudentOverview(recordings: $recordings, newNotes: $newNotes, '
      'practiceThisWeek: $practiceThisWeek)';
}
