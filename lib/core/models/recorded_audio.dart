import 'audio_source.dart';

/// A take of the practice recorder, on this device until it is sent.
class RecordedAudio {
  const RecordedAudio({
    required this.source,
    required this.extension,
    required this.playbackUri,
    required this.sizeBytes,
  });

  /// What the upload reads: the file (Android, iOS) or its bytes (web).
  final AudioSource source;

  /// Without the dot, e.g. `m4a`; a key of AudioFormats.contentTypes.
  final String extension;

  /// What the player loads to listen before sending: a file URI or a blob
  /// URL.
  final Uri playbackUri;
  final int sizeBytes;

  @override
  String toString() => 'RecordedAudio($extension, $sizeBytes bytes)';
}
