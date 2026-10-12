import 'package:file_picker/file_picker.dart';

import '../constants/audio_formats.dart';
import '../models/audio_source.dart';
import '../models/picked_audio_file.dart';
import '../services/audio_file_picker.dart';

/// [AudioFilePicker] on the file_picker plugin: the browser's dialog on the
/// web (the content stays in the browser until read), the system picker on
/// Android and iOS (a file on the device).
class PlatformAudioFilePicker implements AudioFilePicker {
  const PlatformAudioFilePicker();

  @override
  Future<List<PickedAudioFile>> pickAudioFiles() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: AudioFormats.contentTypes.keys.toList(),
    );
    return [
      for (final file in files)
        PickedAudioFile(
          name: file.name,
          sizeBytes: await file.length() ?? 0,
          open: () async => switch (file.path) {
            final path? => FileAudioSource(path),
            null => BytesAudioSource(await file.readAsBytes()),
          },
        ),
    ];
  }
}
