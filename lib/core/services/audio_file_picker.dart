import '../models/picked_audio_file.dart';

/// The system's file picker, for audio files.
abstract class AudioFilePicker {
  /// Lets the user pick one or many audio files (the extensions of
  /// AudioFormats). Empty when they cancel. Files are not checked here:
  /// the caller refuses types and sizes it cannot upload.
  Future<List<PickedAudioFile>> pickAudioFiles();
}
