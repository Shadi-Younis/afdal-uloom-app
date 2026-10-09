import 'dart:typed_data';

// The subclasses must live in this file: Dart only allows subclasses of a
// sealed class in its own library. The one exception to "one public class
// per file".

/// The audio to upload: a file on the device (Android / iOS) or bytes in
/// memory (web, where there is no file system).
sealed class AudioSource {
  const AudioSource();
}

/// A file on the device, e.g. what the recorder or the file picker wrote.
/// Not available on web.
class FileAudioSource extends AudioSource {
  const FileAudioSource(this.path);

  final String path;

  @override
  String toString() => 'FileAudioSource($path)';
}

/// Audio held in memory, e.g. a file picked in the browser.
class BytesAudioSource extends AudioSource {
  const BytesAudioSource(this.bytes);

  final Uint8List bytes;

  @override
  String toString() => 'BytesAudioSource(${bytes.length} bytes)';
}
