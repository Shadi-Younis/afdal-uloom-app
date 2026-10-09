import '../errors/app_exception.dart';
import '../models/playback_status.dart';

/// Plays one audio stream at a time. Wraps the audio package so widgets and
/// controllers are tested with a fake.
abstract class AudioPlayerService {
  /// Loads [url], ready to play from [initialPosition]; resolves to the
  /// duration (null if unknown). Throws [AppException] when the audio
  /// cannot be loaded (e.g. the URL was refused).
  Future<Duration?> load(Uri url, {Duration initialPosition = Duration.zero});

  /// Starts playing; returns once started, not when playback ends.
  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  /// 1.0 is normal speed.
  Future<void> setSpeed(double speed);

  Stream<Duration> get positionStream;

  Stream<Duration?> get durationStream;

  /// The status; a failure while playing arrives as an [AppException]
  /// error event.
  Stream<PlaybackStatus> get statusStream;

  /// Stops and frees the player; it cannot be used afterwards.
  Future<void> dispose();
}
