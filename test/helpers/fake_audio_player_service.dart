import 'dart:async';

import 'package:afdal_uloom_tilawat/core/models/playback_status.dart';
import 'package:afdal_uloom_tilawat/core/services/audio_player_service.dart';

/// An [AudioPlayerService] driven by the test.
///
/// - [loadErrors]: each load takes the next one and throws it; when empty,
///   loads succeed with [duration].
/// - [loadGate]: when set, load waits for it (to test the loading state).
/// - [emitPosition] / [emitStatus] / [emitError]: what the real player
///   would report while playing.
class FakeAudioPlayerService implements AudioPlayerService {
  Duration? duration = const Duration(seconds: 30);
  final loadErrors = <Object>[];
  Completer<void>? loadGate;

  final loads = <(Uri url, Duration at)>[];
  final seeks = <Duration>[];
  final speeds = <double>[];
  var playCalls = 0;
  var pauseCalls = 0;
  var disposed = false;

  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration?>.broadcast();
  final _status = StreamController<PlaybackStatus>.broadcast();

  void emitPosition(Duration position) => _position.add(position);
  void emitStatus(PlaybackStatus status) => _status.add(status);
  void emitError(Object error) => _status.addError(error);

  @override
  Future<Duration?> load(
    Uri url, {
    Duration initialPosition = Duration.zero,
  }) async {
    loads.add((url, initialPosition));
    await loadGate?.future;
    if (loadErrors.isNotEmpty) throw loadErrors.removeAt(0);
    return duration;
  }

  @override
  Future<void> play() async {
    playCalls++;
    _status.add(PlaybackStatus.playing);
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    _status.add(PlaybackStatus.paused);
  }

  @override
  Future<void> seek(Duration position) async => seeks.add(position);

  @override
  Future<void> setSpeed(double speed) async => speeds.add(speed);

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Stream<Duration?> get durationStream => _duration.stream;

  @override
  Stream<PlaybackStatus> get statusStream => _status.stream;

  @override
  Future<void> dispose() async => disposed = true;
}
