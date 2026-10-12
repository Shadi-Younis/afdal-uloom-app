import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/audio_recorder_service.dart';
import 'practice_recorder_state.dart';
import 'recorder_phase.dart';

/// The microphone side of «سجّل تدريباً»: asks for the microphone, records
/// one take with pause / resume, shows its length and level, stops by
/// itself at AppDurations.maxPracticeLength, and keeps the take for
/// listening until it is sent or recorded again. Nothing leaves the phone
/// here: PracticeSubmitController sends.
///
/// Leaving the page (autoDispose) stops a running take and deletes an
/// unsent one.
class PracticeRecorderController extends Notifier<PracticeRecorderState> {
  late AudioRecorderService _recorder;
  late DateTime Function() _now;
  Timer? _ticker;
  StreamSubscription<double>? _levels;

  /// The length recorded before the current stretch (pauses left out).
  var _before = Duration.zero;

  /// When the current stretch of recording started; null while paused.
  DateTime? _since;

  @override
  PracticeRecorderState build() {
    _recorder = ref.watch(audioRecorderServiceProvider);
    _now = ref.watch(clockProvider);
    // onDispose may not read state: the last one is kept here.
    var last = const PracticeRecorderState();
    listenSelf((_, next) => last = next);
    ref.onDispose(() {
      _stopTicking();
      if (last.phase.isCapturing) unawaited(_quietly(_recorder.cancel));
      if (last.take case final take?) {
        unawaited(_quietly(() => _recorder.release(take)));
      }
    });
    return const PracticeRecorderState();
  }

  /// Asks for the microphone (the first time) and starts a new take.
  Future<void> start() async {
    final phase = state.phase;
    if (phase != RecorderPhase.ready &&
        phase != RecorderPhase.permissionDenied) {
      return;
    }
    state = const PracticeRecorderState(phase: RecorderPhase.starting);
    try {
      if (!await _recorder.requestPermission()) {
        if (ref.mounted) {
          state = const PracticeRecorderState(
            phase: RecorderPhase.permissionDenied,
          );
        }
        return;
      }
      await _recorder.start();
    } catch (error, stackTrace) {
      if (ref.mounted) _fail(error, stackTrace);
      return;
    }
    if (!ref.mounted) return;
    _before = Duration.zero;
    _since = _now();
    state = const PracticeRecorderState(phase: RecorderPhase.recording);
    _startTicking();
  }

  Future<void> pause() async {
    if (state.phase != RecorderPhase.recording) return;
    _stopTicking();
    final elapsed = _elapsed();
    _before = elapsed;
    _since = null;
    state = state.copyWith(
      phase: RecorderPhase.paused,
      elapsed: elapsed,
      level: 0,
    );
    try {
      await _recorder.pause();
    } catch (error, stackTrace) {
      if (ref.mounted) await _abandon(error, stackTrace);
    }
  }

  Future<void> resume() async {
    if (state.phase != RecorderPhase.paused) return;
    try {
      await _recorder.resume();
    } catch (error, stackTrace) {
      if (ref.mounted) await _abandon(error, stackTrace);
      return;
    }
    if (!ref.mounted) return;
    _since = _now();
    state = state.copyWith(phase: RecorderPhase.recording);
    _startTicking();
  }

  /// Ends the take; it can then be listened to and sent.
  Future<void> stop() => _stop(limitReached: false);

  /// «إعادة التسجيل»: throws the take away; the page is ready again.
  Future<void> discard() async {
    final take = state.take;
    if (state.phase != RecorderPhase.recorded || take == null) return;
    state = const PracticeRecorderState();
    await _quietly(() => _recorder.release(take));
  }

  /// The take was sent: its file is no longer needed.
  Future<void> sent() => discard();

  /// Opens the phone's settings for this app (where the microphone is
  /// allowed); false in the browser, which has none.
  Future<bool> openSettings() => _recorder.openSettings();

  /// Refreshes the length; stops at the limit. Runs every
  /// AppDurations.recorderTick while recording.
  @visibleForTesting
  void tick() {
    if (!ref.mounted || state.phase != RecorderPhase.recording) return;
    final elapsed = _elapsed();
    if (elapsed >= AppDurations.maxPracticeLength) {
      unawaited(_stop(limitReached: true));
      return;
    }
    state = state.copyWith(elapsed: elapsed);
  }

  Future<void> _stop({required bool limitReached}) async {
    final phase = state.phase;
    if (phase != RecorderPhase.recording && phase != RecorderPhase.paused) {
      return;
    }
    _stopTicking();
    var elapsed = _elapsed();
    if (elapsed > AppDurations.maxPracticeLength) {
      elapsed = AppDurations.maxPracticeLength;
    }
    _since = null;
    state = state.copyWith(
      phase: RecorderPhase.stopping,
      elapsed: elapsed,
      level: 0,
    );
    try {
      final take = await _recorder.stop();
      if (!ref.mounted) {
        await _quietly(() => _recorder.release(take));
        return;
      }
      state = PracticeRecorderState(
        phase: RecorderPhase.recorded,
        elapsed: elapsed,
        take: take,
        limitReached: limitReached,
      );
    } catch (error, stackTrace) {
      if (ref.mounted) _fail(error, stackTrace);
    }
  }

  Duration _elapsed() {
    final since = _since;
    return since == null ? _before : _before + _now().difference(since);
  }

  void _startTicking() {
    _stopTicking();
    _ticker = Timer.periodic(AppDurations.recorderTick, (_) => tick());
    _levels = _recorder.levels(AppDurations.recorderTick).listen(
      (level) {
        if (ref.mounted && state.phase == RecorderPhase.recording) {
          state = state.copyWith(level: level);
        }
      },
      // The meter only: the recording goes on without it.
      onError: (Object _) {},
    );
  }

  void _stopTicking() {
    _ticker?.cancel();
    _ticker = null;
    unawaited(_levels?.cancel());
    _levels = null;
  }

  /// The recorder failed in the middle of a take: it is lost.
  Future<void> _abandon(Object error, StackTrace stackTrace) async {
    _stopTicking();
    await _quietly(_recorder.cancel);
    if (ref.mounted) _fail(error, stackTrace);
  }

  void _fail(Object error, StackTrace stackTrace) {
    _stopTicking();
    _since = null;
    state = PracticeRecorderState(error: AppException.wrap(error, stackTrace));
  }

  static Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // Cleaning up only: nothing the user can do about it.
    }
  }
}

final practiceRecorderControllerProvider =
    NotifierProvider.autoDispose<
      PracticeRecorderController,
      PracticeRecorderState
    >(PracticeRecorderController.new);
