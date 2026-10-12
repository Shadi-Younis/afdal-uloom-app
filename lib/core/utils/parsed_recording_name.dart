/// What the name of a studio file says about its recording; every part is
/// null when it is missing or not understood. See parseRecordingFileName.
class ParsedRecordingName {
  const ParsedRecordingName({
    this.studentCode,
    this.surahNumber,
    this.ayahFrom,
    this.ayahTo,
    this.recordedAt,
  });

  /// Upper case, e.g. `S014`; not checked against any student.
  final String? studentCode;
  final int? surahNumber;
  final int? ayahFrom;
  final int? ayahTo;

  /// The day, when the name has one (`2026-10-05`).
  final DateTime? recordedAt;

  @override
  bool operator ==(Object other) =>
      other is ParsedRecordingName &&
      other.studentCode == studentCode &&
      other.surahNumber == surahNumber &&
      other.ayahFrom == ayahFrom &&
      other.ayahTo == ayahTo &&
      other.recordedAt == recordedAt;

  @override
  int get hashCode =>
      Object.hash(studentCode, surahNumber, ayahFrom, ayahTo, recordedAt);

  @override
  String toString() =>
      'ParsedRecordingName($studentCode, surah: $surahNumber, '
      'ayat: $ayahFrom-$ayahTo, recordedAt: $recordedAt)';
}
