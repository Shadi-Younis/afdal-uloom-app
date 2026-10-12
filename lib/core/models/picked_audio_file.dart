import 'audio_source.dart';

/// An audio file the user picked or dropped, before it is uploaded. Its
/// content is only read when the upload starts ([open]), so many large
/// studio files are not all held in memory at once on the web.
class PickedAudioFile {
  const PickedAudioFile({
    required this.name,
    required this.sizeBytes,
    required this.open,
  });

  /// The file name with its extension, e.g. `S014_002_001-020.mp3`.
  final String name;
  final int sizeBytes;

  /// The content: a file on the device (mobile) or its bytes (web).
  final Future<AudioSource> Function() open;

  /// Lower case, without the dot; empty when the name has none.
  String get extension {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  @override
  String toString() => 'PickedAudioFile($name, $sizeBytes bytes)';
}
