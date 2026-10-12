import 'dart:async';

import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/providers/clock_provider.dart';
import 'package:afdal_uloom_tilawat/core/providers/service_providers.dart';
import 'package:afdal_uloom_tilawat/features/student/application/practice_recorder_controller.dart';
import 'package:afdal_uloom_tilawat/features/student/application/practice_recorder_state.dart';
import 'package:afdal_uloom_tilawat/features/student/application/recorder_phase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_audio_recorder_service.dart';

void main() {
  late FakeAudioRecorderService recorder;
  late ProviderContainer container;
  late DateTime now;

  setUp(() {
    recorder = FakeAudioRecorderService();
    now = DateTime(2026, 10, 12, 17);
    container = ProviderContainer.test(
      overrides: [
        audioRecorderServiceProvider.overrideWith((ref) => recorder),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    // Shown, as on the page (the provider is autoDispose).
    container.listen(practiceRecorderControllerProvider, (_, _) {});
  });

  PracticeRecorderController controller() =>
      container.read(practiceRecorderControllerProvider.notifier);
  PracticeRecorderState state() =>
      container.read(practiceRecorderControllerProvider);

  /// Moves the clock on and lets the timer refresh the length.
  void advance(Duration by) {
    now = now.add(by);
    controller().tick();
  }

  test('starts ready; start asks for the microphone, then records', () async {
    expect(state().phase, RecorderPhase.ready);
    expect(state().hasUnsentAudio, isFalse);

    await controller().start();
    expect(recorder.calls, ['permission', 'start']);
    expect(state().phase, RecorderPhase.recording);
    expect(state().elapsed, Duration.zero);
    expect(state().hasUnsentAudio, isTrue);
  });

  test('while asking: starting (the big button waits)', () async {
    recorder.permissionGate = Completer<void>();
    final starting = controller().start();
    expect(state().phase, RecorderPhase.starting);
    expect(state().phase.isCapturing, isTrue);
    recorder.permissionGate!.complete();
    await starting;
    expect(state().phase, RecorderPhase.recording);
  });

  test('microphone refused: permissionDenied, nothing recorded; allowed '
      'later, the retry records', () async {
    recorder.allowed = false;
    await controller().start();
    expect(state().phase, RecorderPhase.permissionDenied);
    expect(recorder.calls, ['permission']);
    expect(state().hasUnsentAudio, isFalse);

    expect(await controller().openSettings(), isTrue);
    recorder.allowed = true;
    await controller().start();
    expect(state().phase, RecorderPhase.recording);
  });

  test('the microphone fails to open: ready again, with the reason', () async {
    recorder.startError = recordingFailed;
    await controller().start();
    expect(state().phase, RecorderPhase.ready);
    expect(state().error?.code, AppErrorCode.recordingFailed);
  });

  test('the length counts recording time only, not pauses', () async {
    await controller().start();
    advance(const Duration(seconds: 10));
    expect(state().elapsed, const Duration(seconds: 10));

    await controller().pause();
    expect(state().phase, RecorderPhase.paused);
    expect(recorder.calls.last, 'pause');
    now = now.add(const Duration(minutes: 5));
    controller().tick();
    expect(state().elapsed, const Duration(seconds: 10));

    await controller().resume();
    expect(state().phase, RecorderPhase.recording);
    advance(const Duration(seconds: 3));
    expect(state().elapsed, const Duration(seconds: 13));
  });

  test(
    'the meter follows the microphone while recording, 0 when paused',
    () async {
      await controller().start();
      recorder.emitLevel(0.6);
      await Future<void>.delayed(Duration.zero);
      expect(state().level, 0.6);

      await controller().pause();
      expect(state().level, 0);
      recorder.emitLevel(0.9);
      await Future<void>.delayed(Duration.zero);
      expect(state().level, 0);
    },
  );

  test('stop: the take to listen to, with its length', () async {
    await controller().start();
    advance(const Duration(seconds: 42));
    await controller().stop();
    expect(state().phase, RecorderPhase.recorded);
    expect(state().take, isNotNull);
    expect(state().elapsed, const Duration(seconds: 42));
    expect(state().limitReached, isFalse);
    expect(state().hasUnsentAudio, isTrue);
  });

  test('stopping from a pause keeps the length', () async {
    await controller().start();
    advance(const Duration(seconds: 7));
    await controller().pause();
    await controller().stop();
    expect(state().phase, RecorderPhase.recorded);
    expect(state().elapsed, const Duration(seconds: 7));
  });

  test('warns from 25 minutes on', () async {
    await controller().start();
    advance(const Duration(minutes: 24, seconds: 59));
    expect(state().nearLimit, isFalse);
    advance(const Duration(seconds: 1));
    expect(state().nearLimit, isTrue);
  });

  test('stops by itself at 30 minutes', () async {
    await controller().start();
    advance(const Duration(minutes: 29, seconds: 59));
    expect(state().phase, RecorderPhase.recording);
    advance(const Duration(seconds: 2));
    await Future<void>.delayed(Duration.zero);
    expect(recorder.calls.last, 'stop');
    expect(state().phase, RecorderPhase.recorded);
    expect(state().limitReached, isTrue);
    expect(state().elapsed, const Duration(minutes: 30));
    expect(state().nearLimit, isFalse);
  });

  test('«إعادة التسجيل»: the take is thrown away, ready again', () async {
    await controller().start();
    await controller().stop();
    final take = state().take!;
    await controller().discard();
    expect(state(), const PracticeRecorderState());
    expect(recorder.released, [take]);

    await controller().start();
    expect(state().phase, RecorderPhase.recording);
  });

  test('a failed stop loses the take and says why', () async {
    await controller().start();
    recorder.stopError = recordingFailed;
    await controller().stop();
    expect(state().phase, RecorderPhase.ready);
    expect(state().take, isNull);
    expect(state().error?.code, AppErrorCode.recordingFailed);
  });

  test('a failed pause abandons the take', () async {
    await controller().start();
    recorder.pauseError = recordingFailed;
    await controller().pause();
    expect(recorder.calls, contains('cancel'));
    expect(state().phase, RecorderPhase.ready);
    expect(state().error?.code, AppErrorCode.recordingFailed);
  });

  test('leaving the page stops a running take', () async {
    await controller().start();
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(recorder.calls.last, 'cancel');
  });

  test('leaving the page deletes a take not sent', () async {
    await controller().start();
    await controller().stop();
    final take = state().take!;
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(recorder.released, [take]);
  });

  test('start is ignored while recording; pause and resume only when '
      'they apply', () async {
    await controller().resume();
    await controller().pause();
    await controller().stop();
    expect(recorder.calls, isEmpty);

    await controller().start();
    await controller().start();
    expect(recorder.calls, ['permission', 'start']);
  });
}
