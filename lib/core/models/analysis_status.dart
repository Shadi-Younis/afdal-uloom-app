/// Where the server's analysis of an official recording is
/// (`recordings/{id}.analysis.status`). [value] is what Firestore stores.
enum AnalysisStatus {
  /// A two-file recording: both files arrived and the server joins them
  /// into the stereo file (then [pending]).
  merging('merging'),

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

  /// The status [value] names; [pending] for one this version of the app
  /// does not know (a newer server's), so a document never fails to load
  /// because of it. RecordingAnalysis keeps the raw value for the logs.
  static AnalysisStatus fromValue(String value) => values.firstWhere(
    (status) => status.value == value,
    orElse: () => pending,
  );
}
