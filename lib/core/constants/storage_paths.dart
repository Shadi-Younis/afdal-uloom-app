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

  /// What follows the recording id in the name of its playback file.
  static const playbackSuffix = '.play.mp3';

  /// `recordings/{studentId}/{recordingId}.play.mp3`: the centred copy the
  /// server makes of an official recording for listening. Only the server
  /// writes it; it is read with the same rule as the original.
  static String playback(String studentId, String recordingId) =>
      '$recordings/$studentId/$recordingId$playbackSuffix';
}
