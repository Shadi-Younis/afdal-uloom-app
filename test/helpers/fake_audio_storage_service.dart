import 'dart:async';

import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/audio_source.dart';
import 'package:afdal_uloom_tilawat/core/services/audio_storage_service.dart';
import 'package:afdal_uloom_tilawat/core/services/audio_upload.dart';

/// An [AudioStorageService] driven by the test: each upload waits until
/// the test calls [FakeAudioUpload.complete] or [FakeAudioUpload.fail].
///
/// Playback URLs are `https://audio.test/<storagePath>?v=<n>`, where n
/// counts the requests for that path. [urlError] is thrown instead.
class FakeAudioStorageService implements AudioStorageService {
  final uploads = <FakeAudioUpload>[];
  final urlRequests = <(String path, bool refresh)>[];
  Object? urlError;

  FakeAudioUpload get lastUpload => uploads.last;

  @override
  AudioUpload upload({
    required String storagePath,
    required AudioSource source,
    required String contentType,
    void Function(double progress)? onProgress,
  }) {
    final upload = FakeAudioUpload(
      storagePath: storagePath,
      source: source,
      contentType: contentType,
      onProgress: onProgress,
    );
    uploads.add(upload);
    return upload;
  }

  @override
  Future<Uri> getPlaybackUrl(String storagePath, {bool refresh = false}) async {
    urlRequests.add((storagePath, refresh));
    if (urlError case final error?) throw error;
    final count = urlRequests.where((r) => r.$1 == storagePath).length;
    return Uri.parse('https://audio.test/$storagePath?v=$count');
  }
}

class FakeAudioUpload implements AudioUpload {
  FakeAudioUpload({
    required this.storagePath,
    required this.source,
    required this.contentType,
    this.onProgress,
  });

  final String storagePath;
  final AudioSource source;
  final String contentType;
  final void Function(double progress)? onProgress;
  var cancelCalls = 0;

  final _done = Completer<void>();

  @override
  Future<void> get done => _done.future;

  void progress(double value) => onProgress?.call(value);

  void complete() => _done.complete();

  void fail(Object error) => _done.completeError(error);

  @override
  Future<void> cancel() async {
    cancelCalls++;
    if (!_done.isCompleted) {
      _done.completeError(const AppException(AppErrorCode.uploadCancelled));
    }
  }
}
