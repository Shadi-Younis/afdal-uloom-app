import '../models/picked_audio_file.dart';

/// Reads how long a picked audio file is, from its headers (no decoding),
/// so the upload page can show it and check that the two files of a
/// two-file recording are of the same session before anything is sent.
abstract class AudioDurationReader {
  /// The length of [file], or null when its format or headers do not say
  /// (the server checks again after the upload anyway). Never throws.
  Future<Duration?> durationOf(PickedAudioFile file);
}
