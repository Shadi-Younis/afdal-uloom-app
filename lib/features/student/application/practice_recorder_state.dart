import '../../../core/constants/app_durations.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/recorded_audio.dart';
import 'recorder_phase.dart';

/// The state of the practice recorder.
class PracticeRecorderState {
  const PracticeRecorderState({
    this.phase = RecorderPhase.ready,
    this.elapsed = Duration.zero,
    this.level = 0,
    this.take,
    this.limitReached = false,
    this.error,
  });

  final RecorderPhase phase;

  /// How long the take is, pauses left out.
  final Duration elapsed;

  /// The microphone's level, 0..1, while recording.
  final double level;

  /// The finished take, in [RecorderPhase.recorded].
  final RecordedAudio? take;

  /// The take stopped by itself at AppDurations.maxPracticeLength.
  final bool limitReached;

  /// Why the microphone could not be recorded.
  final AppException? error;

  /// AppDurations.practiceLengthWarning is passed while recording.
  bool get nearLimit =>
      phase.isCapturing && elapsed >= AppDurations.practiceLengthWarning;

  /// Leaving the page now would lose a recitation: one being recorded, or
  /// one not sent yet.
  bool get hasUnsentAudio => phase.isCapturing || take != null;

  PracticeRecorderState copyWith({
    RecorderPhase? phase,
    Duration? elapsed,
    double? level,
  }) => PracticeRecorderState(
    phase: phase ?? this.phase,
    elapsed: elapsed ?? this.elapsed,
    level: level ?? this.level,
    take: take,
    limitReached: limitReached,
    error: error,
  );

  @override
  bool operator ==(Object other) =>
      other is PracticeRecorderState &&
      other.phase == phase &&
      other.elapsed == elapsed &&
      other.level == level &&
      other.take == take &&
      other.limitReached == limitReached &&
      other.error?.code == error?.code;

  @override
  int get hashCode =>
      Object.hash(phase, elapsed, level, take, limitReached, error?.code);

  @override
  String toString() =>
      'PracticeRecorderState(${phase.name}, $elapsed, level: $level, '
      'take: $take, limitReached: $limitReached, error: ${error?.code.name})';
}
