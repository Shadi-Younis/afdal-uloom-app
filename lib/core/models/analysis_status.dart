/// Where the server's analysis of an official recording is
/// (`recordings/{id}.analysis.status`). [value] is what Firestore stores.
enum AnalysisStatus {
  /// Uploaded; onRecordingUploaded is working on it.
  pending('pending'),

  /// The sheikh's channel was found; his voice markers are in `feedback`.
  done('done'),

  /// Both channels are the same (not exported with the student left and
  /// the sheikh right): no markers.
  mono('mono'),

  /// The file could not be analysed; the original stays playable.
  failed('failed');

  const AnalysisStatus(this.value);

  final String value;

  /// Throws [FormatException] for a string that is not a known status.
  static AnalysisStatus fromValue(String value) => values.firstWhere(
    (status) => status.value == value,
    orElse: () => throw FormatException('Unknown analysis status', value),
  );
}
