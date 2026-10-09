import '../constants/playback_speeds.dart';
import '../errors/app_exception.dart';
import 'recording_player_phase.dart';

/// The state of RecordingPlayerController.
class RecordingPlayerState {
  const RecordingPlayerState({
    this.phase = RecordingPlayerPhase.loading,
    this.playing = false,
    this.buffering = false,
    this.position = Duration.zero,
    this.duration,
    this.speed = PlaybackSpeeds.normal,
    this.error,
  });

  final RecordingPlayerPhase phase;
  final bool playing;

  /// Loaded, but waiting for more audio from the network.
  final bool buffering;

  /// Where playback is now; a teacher's note "at this second" uses it.
  final Duration position;

  /// Null until the audio is loaded (or if its length is unknown).
  final Duration? duration;
  final double speed;

  /// Why the phase is [RecordingPlayerPhase.error].
  final AppException? error;

  bool get isReady => phase == RecordingPlayerPhase.ready;

  RecordingPlayerState copyWith({
    RecordingPlayerPhase? phase,
    bool? playing,
    bool? buffering,
    Duration? position,
    Duration? duration,
    double? speed,
    AppException? error,
  }) => RecordingPlayerState(
    phase: phase ?? this.phase,
    playing: playing ?? this.playing,
    buffering: buffering ?? this.buffering,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    speed: speed ?? this.speed,
    // An error belongs to the error phase only.
    error: (phase ?? this.phase) == RecordingPlayerPhase.error
        ? error ?? this.error
        : null,
  );

  @override
  bool operator ==(Object other) =>
      other is RecordingPlayerState &&
      other.phase == phase &&
      other.playing == playing &&
      other.buffering == buffering &&
      other.position == position &&
      other.duration == duration &&
      other.speed == speed &&
      other.error?.code == error?.code;

  @override
  int get hashCode => Object.hash(
    phase,
    playing,
    buffering,
    position,
    duration,
    speed,
    error?.code,
  );

  @override
  String toString() =>
      'RecordingPlayerState(${phase.name}, playing: $playing, '
      'buffering: $buffering, position: $position, duration: $duration, '
      'speed: $speed, error: ${error?.code.name})';
}
