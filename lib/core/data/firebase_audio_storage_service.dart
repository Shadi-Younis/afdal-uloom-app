import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../constants/audio_formats.dart';
import '../errors/app_exception.dart';
import '../errors/firebase_error_mapper.dart';
import '../models/audio_source.dart';
import '../services/audio_storage_service.dart';
import '../services/audio_upload.dart';

/// [AudioStorageService] on Cloud Storage for Firebase.
class FirebaseAudioStorageService implements AudioStorageService {
  /// [maxUploadBytes] is only lowered by tests.
  FirebaseAudioStorageService(
    this._storage, {
    this.maxUploadBytes = AudioFormats.maxUploadBytes,
  });

  final FirebaseStorage _storage;
  final int maxUploadBytes;

  // Download URLs do not expire, so one per file is enough for the session.
  final _urls = <String, Uri>{};

  @override
  AudioUpload upload({
    required String storagePath,
    required AudioSource source,
    required String contentType,
    void Function(double progress)? onProgress,
  }) => _FirebaseAudioUpload(
    _storage.ref(storagePath),
    source,
    SettableMetadata(contentType: contentType),
    maxUploadBytes,
    onProgress,
  );

  @override
  Future<Uri> getPlaybackUrl(String storagePath, {bool refresh = false}) async {
    final cached = _urls[storagePath];
    if (cached != null && !refresh) return cached;
    try {
      final url = Uri.parse(await _storage.ref(storagePath).getDownloadURL());
      return _urls[storagePath] = url;
    } catch (error, stackTrace) {
      throw toAppException(error, stackTrace);
    }
  }
}

class _FirebaseAudioUpload implements AudioUpload {
  _FirebaseAudioUpload(
    Reference ref,
    AudioSource source,
    SettableMetadata metadata,
    int maxBytes,
    void Function(double progress)? onProgress,
  ) {
    done = _run(ref, source, metadata, maxBytes, onProgress)
      // Whoever awaits [done] still gets its error; this only keeps an
      // upload that is cancelled and never awaited from being reported as
      // an uncaught error.
      ..ignore();
  }

  @override
  late final Future<void> done;

  UploadTask? _task;
  var _cancelled = false;

  Future<void> _run(
    Reference ref,
    AudioSource source,
    SettableMetadata metadata,
    int maxBytes,
    void Function(double progress)? onProgress,
  ) async {
    try {
      // Checked here so the user gets a clear message instead of the
      // rules' permission error, and nothing is sent.
      final size = await _sizeOf(source);
      if (size == 0) throw const AppException(AppErrorCode.unsupportedFile);
      if (size >= maxBytes) throw const AppException(AppErrorCode.fileTooLarge);
      if (_cancelled) throw const AppException(AppErrorCode.uploadCancelled);

      final task = _task = switch (source) {
        FileAudioSource(:final path) => ref.putFile(File(path), metadata),
        BytesAudioSource(:final bytes) => ref.putData(bytes, metadata),
      };
      final progress = onProgress == null
          ? null
          : task.snapshotEvents.listen(
              (snapshot) {
                if (snapshot.totalBytes > 0) {
                  onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
                }
              },
              // The task itself reports the failure below.
              onError: (Object _) {},
            );
      try {
        await task;
      } finally {
        await progress?.cancel();
      }
      onProgress?.call(1);
    } catch (error, stackTrace) {
      if (_cancelled) {
        throw AppException(
          AppErrorCode.uploadCancelled,
          cause: error,
          stackTrace: stackTrace,
        );
      }
      throw toAppException(error, stackTrace);
    }
  }

  static Future<int> _sizeOf(AudioSource source) => switch (source) {
    FileAudioSource(:final path) => File(path).length(),
    BytesAudioSource(:final bytes) => Future.value(bytes.length),
  };

  @override
  Future<void> cancel() async {
    _cancelled = true;
    await _task?.cancel();
  }
}
