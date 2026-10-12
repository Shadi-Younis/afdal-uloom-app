import '../constants/audio_formats.dart';
import '../errors/app_exception.dart';
import '../models/picked_audio_file.dart';

/// Why [file] can never be uploaded ([AppErrorCode.unsupportedFile]: not an
/// accepted audio type, or empty; [AppErrorCode.fileTooLarge]: at or over
/// AudioFormats.maxUploadBytes), or null when it can.
AppErrorCode? uploadProblemOf(PickedAudioFile file) {
  if (AudioFormats.contentTypeFor(file.extension) == null ||
      file.sizeBytes <= 0) {
    return AppErrorCode.unsupportedFile;
  }
  if (file.sizeBytes >= AudioFormats.maxUploadBytes) {
    return AppErrorCode.fileTooLarge;
  }
  return null;
}
