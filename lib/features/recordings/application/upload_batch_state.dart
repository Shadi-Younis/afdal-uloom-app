import 'upload_row.dart';
import 'upload_row_status.dart';

/// The upload page: its files, and whether «رفع الكل» is running.
class UploadBatchState {
  const UploadBatchState({this.rows = const [], this.running = false});

  final List<UploadRow> rows;

  /// Files are being uploaded, one after another; leaving the page asks
  /// first.
  final bool running;

  /// «رفع الكل» has something to do.
  bool get canUploadAll => !running && rows.any((row) => row.canStart);

  /// How many files are uploaded.
  int get doneCount =>
      rows.where((row) => row.status == UploadRowStatus.done).length;

  UploadRow? row(String key) {
    for (final row in rows) {
      if (row.key == key) return row;
    }
    return null;
  }
}
