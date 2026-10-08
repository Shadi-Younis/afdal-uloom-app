/// Cloud Storage path builders. Firestore stores these paths, never download
/// URLs (docs/PROJECT_PLAN.md section 3).
abstract final class StoragePaths {
  static const recordings = 'recordings';

  /// Studio recordings are mp3.
  static const defaultAudioExtension = 'mp3';

  /// `recordings/{studentId}/{recordingId}.{extension}`. Phone practice
  /// recordings use the recorder's format (e.g. m4a), so the extension is
  /// not always mp3. firestore.rules allows mp3, m4a, aac, wav, ogg, webm.
  static String recording(
    String studentId,
    String recordingId, {
    String extension = defaultAudioExtension,
  }) => '$recordings/$studentId/$recordingId.$extension';
}
