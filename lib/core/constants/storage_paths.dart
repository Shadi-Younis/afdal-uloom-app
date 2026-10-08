/// Cloud Storage path builders. Firestore stores these paths, never download
/// URLs (docs/PROJECT_PLAN.md section 3).
abstract final class StoragePaths {
  static const recordings = 'recordings';

  /// `recordings/{studentId}/{recordingId}.mp3`
  static String recording(String studentId, String recordingId) =>
      '$recordings/$studentId/$recordingId.mp3';
}
