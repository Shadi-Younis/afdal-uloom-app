import 'dart:typed_data';

import 'package:afdal_uloom_tilawat/core/models/audio_source.dart';
import 'package:afdal_uloom_tilawat/core/models/picked_audio_file.dart';
import 'package:afdal_uloom_tilawat/core/services/audio_file_picker.dart';

/// An [AudioFilePicker] that "picks" [next] (then nothing).
class FakeAudioFilePicker implements AudioFilePicker {
  List<PickedAudioFile> next = const [];
  var calls = 0;

  @override
  Future<List<PickedAudioFile>> pickAudioFiles() async {
    calls++;
    final files = next;
    next = const [];
    return files;
  }
}

/// A picked file named [name] of [sizeBytes] bytes (silent content: the
/// tests never play it).
PickedAudioFile pickedFile(String name, {int sizeBytes = 1024}) =>
    PickedAudioFile(
      name: name,
      sizeBytes: sizeBytes,
      open: () async => BytesAudioSource(Uint8List(sizeBytes > 0 ? 4 : 0)),
    );
