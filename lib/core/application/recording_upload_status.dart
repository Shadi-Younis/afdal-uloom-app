/// Where an upload of one recording stands.
enum RecordingUploadStatus {
  /// Nothing started yet (or reset after the last one).
  idle,

  /// Creating the document, then sending the file.
  uploading,

  /// The document and its file are stored.
  done,

  /// Refused or failed; the document was deleted again.
  failed,

  /// Cancelled by the user; the document was deleted again.
  cancelled,
}
