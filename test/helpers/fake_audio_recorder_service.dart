import 'dart:async';
import 'dart:typed_data';

import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/audio_source.dart';
import 'package:afdal_uloom_tilawat/core/models/recorded_audio.dart';
import 'package:afdal_uloom_tilawat/core/services/audio_recorder_service.dart';

/// An [AudioRecorderService] without a microphone: records the calls and
/// returns a small take.
///
/// - [allowed]: what requestPermission answers.
/// - [startError] / [stopError] / [pauseError]: thrown by those calls.
/// - [permissionGate]: when set, requestPermission waits for it.
/// - [emitLevel]: sends a level to the meter, as the microphone would.
class FakeAudioRecorderService implements AudioRecorderService {
  bool allowed = true;
  Object? startError;
  Object? stopError;
  Object? pauseError;
  Completer<void>? permissionGate;

  final calls = <String>[];
  final released = <RecordedAudio>[];
  var disposed = false;
  var _takes = 0;

  final _levels = StreamController<double>.broadcast();

  /// The take [stop] returns next.
  RecordedAudio nextTake() => RecordedAudio(
    source: BytesAudioSource(Uint8List.fromList([1, 2, 3])),
    extension: 'm4a',
    playbackUri: Uri.parse('file:///tmp/practice-${_takes + 1}.m4a'),
    sizeBytes: 3,
  );

  void emitLevel(double level) => _levels.add(level);

  @override
  Future<bool> requestPermission() async {
    calls.add('permission');
    await permissionGate?.future;
    return allowed;
  }

  @override
  Future<void> start() async {
    calls.add('start');
    if (startError case final error?) throw error;
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    if (pauseError case final error?) throw error;
  }

  @override
  Future<void> resume() async => calls.add('resume');

  @override
  Future<RecordedAudio> stop() async {
    calls.add('stop');
    if (stopError case final error?) throw error;
    final take = nextTake();
    _takes++;
    return take;
  }

  @override
  Future<void> cancel() async => calls.add('cancel');

  @override
  Future<void> release(RecordedAudio audio) async => released.add(audio);

  @override
  Stream<double> levels(Duration interval) => _levels.stream;

  @override
  Future<bool> openSettings() async {
    calls.add('settings');
    return true;
  }

  @override
  Future<void> dispose() async => disposed = true;
}

/// What the real recorder throws when the microphone cannot be used.
const recordingFailed = AppException(AppErrorCode.recordingFailed);
