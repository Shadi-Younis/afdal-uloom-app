import 'dart:typed_data';

import 'package:afdal_uloom_tilawat/core/data/firebase_audio_storage_service.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/audio_source.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const path = 'recordings/s001/r1.mp3';
  late MockFirebaseStorage storage;
  late FirebaseAudioStorageService service;

  setUp(() {
    storage = MockFirebaseStorage();
    service = FirebaseAudioStorageService(storage, maxUploadBytes: 10);
  });

  BytesAudioSource bytes(int length) =>
      BytesAudioSource(Uint8List.fromList(List.filled(length, 1)));

  Matcher throwsCode(AppErrorCode code) =>
      throwsA(isA<AppException>().having((e) => e.code, 'code', code));

  group('upload', () {
    // No onProgress: the mock's task snapshots have no byte counts.
    // Progress is covered by the controller tests.
    test('stores the bytes with the content type', () async {
      await service
          .upload(
            storagePath: path,
            source: bytes(4),
            contentType: 'audio/mpeg',
          )
          .done;

      expect(await storage.ref(path).getData(), hasLength(4));
      expect(
        storage.storedSettableMetadataMap[path]?['contentType'],
        'audio/mpeg',
      );
    });

    test('at or over the limit: fileTooLarge, nothing sent', () async {
      final upload = service.upload(
        storagePath: path,
        source: bytes(10),
        contentType: 'audio/mpeg',
      );
      await expectLater(upload.done, throwsCode(AppErrorCode.fileTooLarge));
      expect(storage.storedDataMap.containsKey(path), isFalse);
    });

    test('an empty file: unsupportedFile, nothing sent', () async {
      final upload = service.upload(
        storagePath: path,
        source: bytes(0),
        contentType: 'audio/mpeg',
      );
      await expectLater(upload.done, throwsCode(AppErrorCode.unsupportedFile));
      expect(storage.storedDataMap.containsKey(path), isFalse);
    });

    test(
      'cancelled before it is sent: uploadCancelled, nothing sent',
      () async {
        final upload = service.upload(
          storagePath: path,
          source: bytes(4),
          contentType: 'audio/mpeg',
        );
        await upload.cancel();
        await expectLater(
          upload.done,
          throwsCode(AppErrorCode.uploadCancelled),
        );
        expect(storage.storedDataMap.containsKey(path), isFalse);
      },
    );
  });

  group('getPlaybackUrl', () {
    test('the download URL, kept for the session', () async {
      await service
          .upload(
            storagePath: path,
            source: bytes(4),
            contentType: 'audio/mpeg',
          )
          .done;
      final url = await service.getPlaybackUrl(path);
      expect(url.toString(), contains('recordings/s001/r1.mp3'));

      // Cached: still returned after the file is gone; refresh asks again.
      await storage.ref(path).delete();
      expect(await service.getPlaybackUrl(path), url);
      await expectLater(
        service.getPlaybackUrl(path, refresh: true),
        throwsCode(AppErrorCode.notFound),
      );
    });

    test('a missing file: notFound', () async {
      await expectLater(
        service.getPlaybackUrl('recordings/s001/none.mp3'),
        throwsCode(AppErrorCode.notFound),
      );
    });
  });
}
