import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../errors/app_exception.dart';
import '../models/playback_status.dart';
import '../services/audio_player_service.dart';

/// [AudioPlayerService] on just_audio (ExoPlayer, AVPlayer, HTML audio).
class JustAudioPlayerService implements AudioPlayerService {
  JustAudioPlayerService() : this.withPlayer(AudioPlayer());

  JustAudioPlayerService.withPlayer(this._player) {
    _subscriptions
      ..add(
        _player.playerStateStream.listen((state) {
          // just_audio keeps `playing` true at the end; stop there instead,
          // so play starts again from a seek or from the beginning.
          if (state.processingState == ProcessingState.completed &&
              state.playing) {
            unawaited(_player.pause());
          }
          _status.add(_statusOf(state));
        }),
      )
      ..add(
        _player.playbackEventStream.listen(
          null,
          onError: (Object error, StackTrace stackTrace) =>
              _status.addError(_toAppException(error, stackTrace)),
        ),
      );
  }

  final AudioPlayer _player;
  final _status = StreamController<PlaybackStatus>.broadcast();
  final _subscriptions = <StreamSubscription<Object?>>[];

  @override
  Future<Duration?> load(
    Uri url, {
    Duration initialPosition = Duration.zero,
  }) async {
    try {
      return await _player.setUrl(
        url.toString(),
        initialPosition: initialPosition,
      );
    } catch (error, stackTrace) {
      throw _toAppException(error, stackTrace);
    }
  }

  // just_audio's play() completes only when playback stops.
  @override
  Future<void> play() async => unawaited(_player.play());

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<PlaybackStatus> get statusStream => _status.stream;

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _status.close();
    await _player.dispose();
  }

  static PlaybackStatus _statusOf(PlayerState state) =>
      switch (state.processingState) {
        ProcessingState.idle => PlaybackStatus.idle,
        ProcessingState.loading ||
        ProcessingState.buffering => PlaybackStatus.loading,
        ProcessingState.ready =>
          state.playing ? PlaybackStatus.playing : PlaybackStatus.paused,
        ProcessingState.completed => PlaybackStatus.completed,
      };

  /// HTTP 401 / 403 (a refused or revoked URL) is permissionDenied, 404
  /// notFound; any other load failure is treated as a network problem.
  static AppException _toAppException(Object error, StackTrace stackTrace) {
    final code = switch (error) {
      PlayerException(code: 401 || 403) => AppErrorCode.permissionDenied,
      PlayerException(code: 404) => AppErrorCode.notFound,
      PlayerException() => AppErrorCode.network,
      _ => AppErrorCode.unknown,
    };
    return AppException(code, cause: error, stackTrace: stackTrace);
  }
}
