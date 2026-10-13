import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../constants/audio_formats.dart';
import '../errors/app_exception.dart';
import '../models/audio_source.dart';
import '../models/recorded_audio.dart';
import '../services/audio_recorder_service.dart';
import '../utils/audio_level.dart';

/// [AudioRecorderService] on the record package: MediaRecorder in the
/// browser, the platform recorders on Android and iOS. A take goes to a
/// temporary file on the phone, to a blob in the browser.
class RecordAudioRecorderService implements AudioRecorderService {
  RecordAudioRecorderService([AudioRecorder? recorder])
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  String _extension = AudioFormats.recorderMobileExtension;

  @override
  Future<bool> requestPermission() => _guard(_recorder.hasPermission);

  @override
  Future<void> start() => _guard(() async {
    final encoder = await _encoder();
    final path = kIsWeb ? '' : await _newFilePath();
    await _recorder.start(
      RecordConfig(
        encoder: encoder,
        bitRate: AudioFormats.recorderBitRate,
        sampleRate: AudioFormats.recorderSampleRate,
        numChannels: AudioFormats.recorderChannels,
      ),
      path: path,
    );
  });

  @override
  Future<void> pause() => _guard(_recorder.pause);

  @override
  Future<void> resume() => _guard(_recorder.resume);

  @override
  Future<RecordedAudio> stop() => _guard(() async {
    final location = await _recorder.stop();
    if (location == null || location.isEmpty) {
      throw const AppException(AppErrorCode.recordingFailed);
    }
    if (kIsWeb) {
      // A blob URL of this page: the upload needs its bytes.
      final bytes = await http.readBytes(Uri.parse(location));
      return RecordedAudio(
        source: BytesAudioSource(bytes),
        extension: _extension,
        playbackUri: Uri.parse(location),
        sizeBytes: bytes.length,
      );
    }
    return RecordedAudio(
      source: FileAudioSource(location),
      extension: _extension,
      playbackUri: Uri.file(location),
      sizeBytes: await File(location).length(),
    );
  });

  @override
  Future<void> cancel() => _guard(_recorder.cancel);

  @override
  Future<void> release(RecordedAudio audio) async {
    if (audio.source case FileAudioSource(:final path)) {
      try {
        await File(path).delete();
      } on FileSystemException {
        // Already gone: the system may clear its temporary folder.
      }
    }
  }

  @override
  Stream<double> levels(Duration interval) => _recorder
      .onAmplitudeChanged(interval)
      .map((amplitude) => meterLevelFromDb(amplitude.current));

  @override
  Future<bool> openSettings() async {
    if (kIsWeb) return false;
    await AppSettings.openAppSettings();
    return true;
  }

  @override
  Future<void> dispose() => _recorder.dispose();

  /// Opus in WebM in the browser; Safari has no WebM recorder and gets AAC
  /// (in an .m4a) like the phones.
  Future<AudioEncoder> _encoder() async {
    if (kIsWeb && await _recorder.isEncoderSupported(AudioEncoder.opus)) {
      _extension = AudioFormats.recorderWebExtension;
      return AudioEncoder.opus;
    }
    _extension = AudioFormats.recorderMobileExtension;
    return AudioEncoder.aacLc;
  }

  Future<String> _newFilePath() async {
    final folder = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return '${folder.path}${Platform.pathSeparator}practice-$stamp.$_extension';
  }

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      throw AppException(
        AppErrorCode.recordingFailed,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}
