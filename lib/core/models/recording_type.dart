/// Where a recording comes from. [value] is what Firestore stores in
/// `recordings/{id}.type`.
enum RecordingType {
  /// Recorded in the school studio and uploaded by the teacher.
  official('official'),

  /// Recorded by the student for the teacher to review.
  practice('practice');

  const RecordingType(this.value);

  final String value;

  /// Throws [FormatException] for a string that is not a known type.
  static RecordingType fromValue(String value) => values.firstWhere(
    (type) => type.value == value,
    orElse: () => throw FormatException('Unknown recording type', value),
  );
}
