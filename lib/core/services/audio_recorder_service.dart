import '../errors/app_exception.dart';
import '../models/recorded_audio.dart';

/// Records the microphone for a practice recitation: mono, in the format of
/// AudioFormats (AAC .m4a on Android and iOS, Opus .webm in the browser).
/// One take at a time. Wraps the recorder package so controllers are tested
/// with a fake.
abstract class AudioRecorderService {
  /// Whether the app may use the microphone. The first time, the system (or
  /// the browser) asks the user; false once they refused.
  Future<bool> requestPermission();

  /// Starts a new take. Throws [AppException] with
  /// [AppErrorCode.recordingFailed] when the microphone cannot be opened.
  Future<void> start();

  Future<void> pause();

  Future<void> resume();

  /// Ends the take and returns it. Throws [AppException] with
  /// [AppErrorCode.recordingFailed] when nothing was recorded.
  Future<RecordedAudio> stop();

  /// Ends the running take, if any, and throws it away.
  Future<void> cancel();

  /// Frees a take that is no longer needed (sent or recorded again): its
  /// temporary file is deleted.
  Future<void> release(RecordedAudio audio);

  /// The microphone's level, 0 (silence) to 1 (loud), about every
  /// [interval] while recording.
  Stream<double> levels(Duration interval);

  /// Opens this app's page in the phone's settings, where the microphone
  /// can be allowed. False where there is none (the browser).
  Future<bool> openSettings();

  /// Stops and frees the recorder; it cannot be used afterwards.
  Future<void> dispose();
}
