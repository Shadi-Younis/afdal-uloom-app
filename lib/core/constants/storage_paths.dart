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

  /// `recordings/{studentId}/{recordingId}.{stem}.{extension}`: one file of
  /// a two-file recording, [stem] being [stemStudent] or [stemSheikh]. The
  /// server joins both into the recording's storagePath
  /// (`{recordingId}.mp3`, [defaultAudioExtension]) and deletes them.
  static String stem(
    String studentId,
    String recordingId,
    String stem, {
    required String extension,
  }) => '$recordings/$studentId/$recordingId.$stem.$extension';

  static const stemStudent = 'student';
  static const stemSheikh = 'sheikh';

  /// What follows the recording id in the name of its playback file.
  static const playbackSuffix = '.play.mp3';

  /// `recordings/{studentId}/{recordingId}.play.mp3`: the centred copy the
  /// server makes of an official recording for listening. Only the server
  /// writes it; it is read with the same rule as the original.
  static String playback(String studentId, String recordingId) =>
      '$recordings/$studentId/$recordingId$playbackSuffix';
}
