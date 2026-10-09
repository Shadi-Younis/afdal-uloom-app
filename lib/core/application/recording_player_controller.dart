import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/playback_speeds.dart';
import '../errors/app_exception.dart';
import '../models/playback_status.dart';
import '../providers/service_providers.dart';
import '../services/audio_player_service.dart';
import '../services/audio_storage_service.dart';
import 'recording_player_phase.dart';
import 'recording_player_state.dart';

/// Plays the recording at [storagePath]: gets its URL, loads it, and runs
/// play / pause / seek / speed. When loading fails (also in the middle of
/// playback) it tries once more with a fresh URL, at the same position.
///
/// The player stops when the screen is left: this provider and the one
/// audio player are both autoDispose.
class RecordingPlayerController extends Notifier<RecordingPlayerState> {
  RecordingPlayerController(this.storagePath);

  final String storagePath;

  late AudioPlayerService _player;
  late AudioStorageService _storage;

  // Each load gets a number; a slower, older load must not overwrite a
  // newer one's result.
  var _loadNumber = 0;

  // Reached the end. Until the next seek, play or load, positions from the
  // player are ignored: after a seek, just_audio reported the old seek
  // position again at the end (seen on Android), which showed "paused at
  // 00:12" for a finished recording.
  var _completed = false;

  @override
  RecordingPlayerState build() {
    _player = ref.watch(audioPlayerServiceProvider);
    _storage = ref.watch(audioStorageServiceProvider);
    final subscriptions = [
      _player.positionStream.listen(_onPosition),
      _player.durationStream.listen(_onDuration),
      _player.statusStream.listen(_onStatus, onError: _onPlayerError),
    ];
    ref.onDispose(() {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
    });
    // After build has returned the loading state.
    Future.microtask(() => _load(at: Duration.zero, resume: false));
    return const RecordingPlayerState();
  }

  /// Where playback is now, e.g. for a teacher's note "at this second".
  Duration get position => state.position;

  Future<void> play() async {
    if (!state.isReady) return;
    final duration = state.duration;
    if (_completed || (duration != null && state.position >= duration)) {
      await seek(Duration.zero);
    }
    state = state.copyWith(playing: true);
    await _player.play();
  }

  Future<void> pause() async {
    if (!state.isReady) return;
    state = state.copyWith(playing: false);
    await _player.pause();
  }

  Future<void> togglePlay() => state.playing ? pause() : play();

  /// Jumps to [position], kept inside the recording. Also works while
  /// loading: the player starts there once loaded.
  Future<void> seek(Duration position) async {
    _completed = false;
    final target = _clamp(position);
    state = state.copyWith(position: target);
    if (state.isReady) await _player.seek(target);
  }

  /// Back (negative [delta]) or forward from the current position.
  Future<void> skip(Duration delta) => seek(state.position + delta);

  /// One of [PlaybackSpeeds.all].
  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    if (state.isReady) await _player.setSpeed(speed);
  }

  /// After an error: loads again with a fresh URL.
  Future<void> retry() =>
      _load(at: state.position, resume: false, freshUrl: true);

  Future<void> _load({
    required Duration at,
    required bool resume,
    bool freshUrl = false,
  }) async {
    if (!ref.mounted) return;
    final number = ++_loadNumber;
    _completed = false;
    state = state.copyWith(
      phase: RecordingPlayerPhase.loading,
      playing: false,
      buffering: false,
      position: at,
    );
    try {
      final url = await _storage.getPlaybackUrl(storagePath, refresh: freshUrl);
      final duration = await _player.load(url, initialPosition: at);
      if (!ref.mounted || number != _loadNumber) return;
      state = state.copyWith(
        phase: RecordingPlayerPhase.ready,
        duration: duration,
      );
      // A seek made while loading, e.g. a note's time tapped early.
      if (state.position != at) await _player.seek(state.position);
      if (state.speed != PlaybackSpeeds.normal) {
        await _player.setSpeed(state.speed);
      }
      if (resume) await play();
    } catch (error, stackTrace) {
      if (!ref.mounted || number != _loadNumber) return;
      if (!freshUrl) {
        // Once more with a fresh URL: the cached one may have been revoked.
        return _load(at: at, resume: resume, freshUrl: true);
      }
      state = state.copyWith(
        phase: RecordingPlayerPhase.error,
        playing: false,
        error: AppException.wrap(error, stackTrace),
      );
    }
  }

  void _onPosition(Duration position) {
    if (state.isReady && !_completed) {
      state = state.copyWith(position: _clamp(position));
    }
  }

  void _onDuration(Duration? duration) {
    if (duration != null) state = state.copyWith(duration: duration);
  }

  void _onStatus(PlaybackStatus status) {
    if (!state.isReady) return;
    if (status == PlaybackStatus.completed) _completed = true;
    state = switch (status) {
      PlaybackStatus.playing => state.copyWith(playing: true, buffering: false),
      PlaybackStatus.paused => state.copyWith(playing: false, buffering: false),
      PlaybackStatus.loading => state.copyWith(buffering: true),
      PlaybackStatus.completed => state.copyWith(
        playing: false,
        buffering: false,
        position: state.duration,
      ),
      PlaybackStatus.idle => state,
    };
  }

  /// The stream failed after loading, e.g. its URL stopped working.
  void _onPlayerError(Object error, StackTrace stackTrace) {
    // While loading, load() itself reports the failure.
    if (!state.isReady) return;
    unawaited(_load(at: state.position, resume: state.playing, freshUrl: true));
  }

  Duration _clamp(Duration position) {
    if (position < Duration.zero) return Duration.zero;
    final duration = state.duration;
    return duration != null && position > duration ? duration : position;
  }
}

final recordingPlayerControllerProvider = NotifierProvider.autoDispose
    .family<RecordingPlayerController, RecordingPlayerState, String>(
      RecordingPlayerController.new,
    );
