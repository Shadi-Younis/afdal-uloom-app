import 'dart:io';
import 'dart:typed_data';

import '../models/audio_source.dart';
import '../models/picked_audio_file.dart';
import '../services/audio_duration_reader.dart';
import '../utils/audio_duration.dart';

/// [AudioDurationReader] on the file's own headers (audioDurationOf): the
/// bytes in the browser, the file on Android / iOS.
class HeaderAudioDurationReader implements AudioDurationReader {
  const HeaderAudioDurationReader();

  @override
  Future<Duration?> durationOf(PickedAudioFile file) async {
    try {
      final Uint8List bytes = switch (await file.open()) {
        BytesAudioSource(:final bytes) => bytes,
        FileAudioSource(:final path) => await File(path).readAsBytes(),
      };
      return audioDurationOf(bytes, file.extension);
    } on Object {
      // Only a hint for the page: unreadable means unknown.
      return null;
    }
  }
}
