import 'dart:async';

import 'package:afdal_uloom_tilawat/core/application/recording_player_controller.dart';
import 'package:afdal_uloom_tilawat/core/application/recording_player_phase.dart';
import 'package:afdal_uloom_tilawat/core/application/recording_player_state.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/playback_status.dart';
import 'package:afdal_uloom_tilawat/core/providers/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_audio_player_service.dart';
import '../../helpers/fake_audio_storage_service.dart';

void main() {
  const path = 'recordings/s001/rec-02.wav';
  late FakeAudioPlayerService player;
  late FakeAudioStorageService storage;
  late ProviderContainer container;

  final provider = recordingPlayerControllerProvider(path);
  RecordingPlayerController controller() => container.read(provider.notifier);
  RecordingPlayerState state() => container.read(provider);

  Uri url(int version) => Uri.parse('https://audio.test/$path?v=$version');
  const denied = AppException(AppErrorCode.permissionDenied);

  /// Lets the microtask-started load and the fakes' futures complete.
  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    player = FakeAudioPlayerService();
    storage = FakeAudioStorageService();
    container = ProviderContainer.test(
      overrides: [
        // Like the real provider: disposes the player when unused.
        audioPlayerServiceProvider.overrideWith((ref) {
          ref.onDispose(player.dispose);
          return player;
        }),
        audioStorageServiceProvider.overrideWithValue(storage),
      ],
    );
  });

  /// Shows the player, as the screen does; loading starts now, so arrange
  /// the fakes before.
  ProviderSubscription<RecordingPlayerState> start() =>
      container.listen(provider, (_, _) {});

  Future<void> loaded() async {
    start();
    await settle();
    expect(state().phase, RecordingPlayerPhase.ready);
  }

  test('starts loading, then is ready with the duration', () async {
    player.loadGate = Completer<void>();
    start();
    await settle();
    expect(state().phase, RecordingPlayerPhase.loading);
    expect(storage.urlRequests, [(path, false)]);

    player.loadGate!.complete();
    await settle();
    expect(state().phase, RecordingPlayerPhase.ready);
    expect(state().duration, const Duration(seconds: 30));
    expect(state().position, Duration.zero);
    expect(state().playing, isFalse);
    expect(player.loads.single.$1, url(1));
  });

  test('play and pause, following the player', () async {
    await loaded();
    await controller().togglePlay();
    await settle();
    expect(player.playCalls, 1);
    expect(state().playing, isTrue);

    player.emitPosition(const Duration(seconds: 4));
    await settle();
    expect(state().position, const Duration(seconds: 4));
    expect(controller().position, const Duration(seconds: 4));

    await controller().togglePlay();
    await settle();
    expect(player.pauseCalls, 1);
    expect(state().playing, isFalse);
  });

  test('buffering while playing is shown, then cleared', () async {
    await loaded();
    await controller().play();
    player.emitStatus(PlaybackStatus.loading);
    await settle();
    expect(state().buffering, isTrue);
    expect(state().playing, isTrue);
    player.emitStatus(PlaybackStatus.playing);
    await settle();
    expect(state().buffering, isFalse);
  });

  test('seek and skip stay inside the recording', () async {
    await loaded();
    await controller().seek(const Duration(seconds: 10));
    expect(state().position, const Duration(seconds: 10));
    await controller().skip(const Duration(seconds: 5));
    expect(state().position, const Duration(seconds: 15));
    await controller().skip(const Duration(seconds: -20));
    expect(state().position, Duration.zero);
    await controller().seek(const Duration(minutes: 5));
    expect(state().position, const Duration(seconds: 30));
    expect(player.seeks, [
      const Duration(seconds: 10),
      const Duration(seconds: 15),
      Duration.zero,
      const Duration(seconds: 30),
    ]);
  });

  test('at the end, play starts again from the beginning', () async {
    await loaded();
    await controller().play();
    player.emitStatus(PlaybackStatus.completed);
    await settle();
    expect(state().playing, isFalse);
    expect(state().position, const Duration(seconds: 30));

    await controller().play();
    expect(player.seeks.last, Duration.zero);
    expect(state().playing, isTrue);
  });

  // Seen on a phone: after a seek, at the end just_audio reported the old
  // seek position again; the player then showed "paused at 00:12" and play
  // restarted from 0 instead.
  test('a stale position after the end is ignored; play rewinds', () async {
    await loaded();
    await controller().seek(const Duration(seconds: 12));
    await controller().play();
    player.emitStatus(PlaybackStatus.completed);
    player.emitPosition(const Duration(seconds: 12));
    await settle();
    expect(state().position, const Duration(seconds: 30));
    expect(state().playing, isFalse);

    await controller().play();
    expect(player.seeks.last, Duration.zero);
    expect(state().position, Duration.zero);
    player.emitPosition(const Duration(seconds: 1));
    await settle();
    expect(state().position, const Duration(seconds: 1));
  });

  test('a seek after the end plays on from there', () async {
    await loaded();
    await controller().play();
    player.emitStatus(PlaybackStatus.completed);
    await settle();
    await controller().seek(const Duration(seconds: 20));
    player.emitPosition(const Duration(seconds: 20));
    await settle();
    expect(state().position, const Duration(seconds: 20));
    await controller().play();
    expect(player.seeks.last, const Duration(seconds: 20));
  });

  test('speed 0.75 / 1 / 1.25', () async {
    await loaded();
    await controller().setSpeed(1.25);
    expect(state().speed, 1.25);
    await controller().setSpeed(0.75);
    expect(player.speeds, [1.25, 0.75]);
  });

  test('a seek while loading is applied once loaded', () async {
    player.loadGate = Completer<void>();
    start();
    await settle();
    await controller().seek(const Duration(seconds: 12));
    expect(player.seeks, isEmpty);
    player.loadGate!.complete();
    await settle();
    expect(player.seeks, [const Duration(seconds: 12)]);
    expect(state().position, const Duration(seconds: 12));
  });

  test('a load error retries once with a fresh URL', () async {
    player.loadErrors.add(denied);
    start();
    await settle();
    expect(storage.urlRequests, [(path, false), (path, true)]);
    expect(player.loads.map((l) => l.$1), [url(1), url(2)]);
    expect(state().phase, RecordingPlayerPhase.ready);
  });

  test('two load errors: the Arabic error state, then retry works', () async {
    player.loadErrors.addAll([denied, denied]);
    start();
    await settle();
    expect(state().phase, RecordingPlayerPhase.error);
    expect(state().error?.code, AppErrorCode.permissionDenied);
    expect(player.loads, hasLength(2));

    await controller().retry();
    await settle();
    expect(state().phase, RecordingPlayerPhase.ready);
    expect(storage.urlRequests.last, (path, true));
  });

  test('no URL (e.g. access denied): error after one retry', () async {
    storage.urlError = denied;
    start();
    await settle();
    expect(state().phase, RecordingPlayerPhase.error);
    expect(state().error?.code, AppErrorCode.permissionDenied);
    expect(storage.urlRequests, [(path, false), (path, true)]);
    expect(player.loads, isEmpty);
  });

  test(
    'the stream fails while playing: fresh URL, same position, resumes',
    () async {
      await loaded();
      await controller().play();
      player.emitPosition(const Duration(seconds: 9));
      await settle();

      player.emitError(denied);
      await settle();
      expect(storage.urlRequests.last, (path, true));
      expect(player.loads.last, (url(2), const Duration(seconds: 9)));
      expect(state().phase, RecordingPlayerPhase.ready);
      expect(state().position, const Duration(seconds: 9));
      expect(state().playing, isTrue);
      expect(player.playCalls, 2);
    },
  );

  test('the speed survives a reload', () async {
    await loaded();
    await controller().setSpeed(1.25);
    player.emitError(denied);
    await settle();
    expect(player.speeds, [1.25, 1.25]);
  });

  test('leaving the screen disposes the controller and the player', () async {
    final shown = start();
    await settle();
    expect(state().phase, RecordingPlayerPhase.ready);

    shown.close();
    await settle();
    expect(player.disposed, isTrue);
  });
}
