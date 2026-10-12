/// Where one file of the upload page is.
enum UploadRowStatus {
  /// Not started: its fields can still be edited.
  editing,

  /// In «رفع الكل»'s queue, waiting for the files before it.
  waiting,
  uploading,
  done,
  failed,
  cancelled;

  /// Its fields may change, and it may be removed.
  bool get isEditable => this == editing || this == failed || this == cancelled;
}
