/// How an official recording's audio was exported from the studio
/// (`recordings/{id}.source`). [value] is what Firestore stores; a document
/// without the field is [stereo].
enum RecordingSource {
  /// One stereo file: the student LEFT, the sheikh RIGHT
  /// («ملف واحد (يسار/يمين)»).
  stereo('stereo'),

  /// Two files, one per microphone (Studio One «Export Stems»), that the
  /// server joins into the stereo file at `storagePath`
  /// («ملفين: الطالب + الشيخ»).
  stems('stems');

  const RecordingSource(this.value);

  final String value;

  /// The source [value] names; [stereo] for null (documents from before
  /// Task 11) and for one this version of the app does not know, so a
  /// document never fails to load because of it.
  static RecordingSource fromValue(String? value) => values.firstWhere(
    (source) => source.value == value,
    orElse: () => stereo,
  );
}
