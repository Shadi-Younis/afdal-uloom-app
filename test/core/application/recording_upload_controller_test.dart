import 'dart:async';
import 'dart:typed_data';

import 'package:afdal_uloom_tilawat/core/application/recording_upload_controller.dart';
import 'package:afdal_uloom_tilawat/core/application/recording_upload_request.dart';
import 'package:afdal_uloom_tilawat/core/application/recording_upload_state.dart';
import 'package:afdal_uloom_tilawat/core/application/recording_upload_status.dart';
import 'package:afdal_uloom_tilawat/core/application/session_providers.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/audio_source.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_source.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_type.dart';
import 'package:afdal_uloom_tilawat/core/models/stem_paths.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/providers/repository_providers.dart';
import 'package:afdal_uloom_tilawat/core/providers/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_audio_storage_service.dart';
import '../../helpers/fake_auth_service.dart';
import '../../helpers/fake_recording_repository.dart';

void main() {
  late FakeRecordingRepository recordings;
  late FakeAudioStorageService storage;
  late ProviderContainer container;
  late List<RecordingUploadState> states;

  final source = BytesAudioSource(Uint8List.fromList([1, 2, 3]));
  RecordingUploadRequest request({
    String extension = 'mp3',
    RecordingType type = RecordingType.official,
    int surah = 2,
    int from = 1,
    int to = 20,
  }) => RecordingUploadRequest(
    studentId: 's001',
    halaqaId: 'halaqa-fajr',
    teacherId: 't01',
    type: type,
    surahNumber: surah,
    ayahFrom: from,
    ayahTo: to,
    recordedAt: DateTime(2026, 10, 5, 16),
    source: source,
    fileExtension: extension,
  );

  Future<void> setUpAs(AuthSession? session) async {
    recordings = FakeRecordingRepository();
    storage = FakeAudioStorageService();
    container = ProviderContainer.test(
      overrides: [
        authServiceProvider.overrideWithValue(
          FakeAuthService(initial: session),
        ),
        recordingRepositoryProvider.overrideWithValue(recordings),
        audioStorageServiceProvider.overrideWithValue(storage),
      ],
    );
    // Listened, as the screens do: Riverpod pauses an unlistened provider.
    container.listen(sessionProvider, (_, _) {});
    await container.read(sessionProvider.future);
    states = [];
    container.listen(
      recordingUploadControllerProvider('row-1'),
      (_, next) => states.add(next),
      fireImmediately: true,
    );
  }

  RecordingUploadController controller() =>
      container.read(recordingUploadControllerProvider('row-1').notifier);
  RecordingUploadState state() =>
      container.read(recordingUploadControllerProvider('row-1'));

  /// Lets create() finish and the upload start.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('as the teacher', () {
    setUp(() => setUpAs(const AuthSession(uid: 't01', role: UserRole.teacher)));

    test('creates the document, uploads with progress, ends done', () async {
      final result = controller().start(request());
      await settle();

      expect(recordings.created, hasLength(1));
      final doc = recordings.created.single;
      expect(doc.id, 'new-1');
      expect(doc.storagePath, 'recordings/s001/new-1.mp3');
      expect(doc.uploadedBy, 't01');
      expect(doc.studentId, 's001');
      // Waits for the sheikh to check its voice markers.
      expect(doc.reviewed, isFalse);
      expect(doc.unreadFeedback, isFalse);
      final upload = storage.lastUpload;
      expect(upload.storagePath, 'recordings/s001/new-1.mp3');
      expect(upload.contentType, 'audio/mpeg');
      expect(upload.source, same(source));

      upload.progress(0.5);
      expect(state().status, RecordingUploadStatus.uploading);
      expect(state().progress, 0.5);
      upload.complete();

      expect(await result, 'new-1');
      expect(state().status, RecordingUploadStatus.done);
      expect(state().recordingId, 'new-1');
      expect(state().progress, 1);
      expect(recordings.deleted, isEmpty);
      expect(states.map((s) => (s.status, s.progress)), [
        (RecordingUploadStatus.idle, 0.0),
        (RecordingUploadStatus.uploading, 0.0),
        (RecordingUploadStatus.uploading, 0.5),
        (RecordingUploadStatus.done, 1.0),
      ]);
    });

    test('the extension picks path and content type, any case', () async {
      final result = controller().start(request(extension: 'M4A'));
      await settle();
      expect(storage.lastUpload.storagePath, 'recordings/s001/new-1.m4a');
      expect(storage.lastUpload.contentType, 'audio/mp4');
      storage.lastUpload.complete();
      await result;
    });

    test('an unsupported file is refused before anything is written', () async {
      expect(await controller().start(request(extension: 'exe')), isNull);
      expect(state().status, RecordingUploadStatus.failed);
      expect(state().error?.code, AppErrorCode.unsupportedFile);
      expect(recordings.created, isEmpty);
      expect(storage.uploads, isEmpty);
    });

    test(
      'ayat outside the surah are refused before anything is written',
      () async {
        expect(await controller().start(request(surah: 1, to: 8)), isNull);
        expect(state().error?.code, AppErrorCode.invalidData);
        expect(recordings.created, isEmpty);
      },
    );

    test('create refused: failed, no upload, nothing to delete', () async {
      recordings.createError = const AppException(
        AppErrorCode.permissionDenied,
      );
      expect(await controller().start(request()), isNull);
      expect(state().status, RecordingUploadStatus.failed);
      expect(state().error?.code, AppErrorCode.permissionDenied);
      expect(storage.uploads, isEmpty);
      expect(recordings.deleted, isEmpty);
    });

    test('upload fails: the document is deleted, the error shown', () async {
      final result = controller().start(request());
      await settle();
      storage.lastUpload.fail(const AppException(AppErrorCode.fileTooLarge));

      expect(await result, isNull);
      expect(recordings.deleted, ['new-1']);
      expect(state().status, RecordingUploadStatus.failed);
      expect(state().error?.code, AppErrorCode.fileTooLarge);
    });

    test('a non-AppException upload error is wrapped as unknown', () async {
      final result = controller().start(request());
      await settle();
      storage.lastUpload.fail(StateError('boom'));
      expect(await result, isNull);
      expect(state().error?.code, AppErrorCode.unknown);
      expect(recordings.deleted, ['new-1']);
    });

    test(
      'the delete after a failure may fail too: the upload error stays',
      () async {
        recordings.deleteError = const AppException(AppErrorCode.network);
        final result = controller().start(request());
        await settle();
        storage.lastUpload.fail(const AppException(AppErrorCode.network));
        expect(await result, isNull);
        expect(state().status, RecordingUploadStatus.failed);
        expect(state().error?.code, AppErrorCode.network);
      },
    );

    test('cancel during the upload: cancelled, document deleted', () async {
      final result = controller().start(request());
      await settle();
      await controller().cancel();

      expect(await result, isNull);
      expect(storage.lastUpload.cancelCalls, 1);
      expect(recordings.deleted, ['new-1']);
      expect(state().status, RecordingUploadStatus.cancelled);
      expect(state().error, isNull);
    });

    test('cancel while the document is created: no upload starts', () async {
      recordings.createGate = Completer<void>();
      final result = controller().start(request());
      await settle();
      await controller().cancel();
      recordings.createGate!.complete();

      expect(await result, isNull);
      expect(storage.uploads, isEmpty);
      expect(recordings.deleted, ['new-1']);
      expect(state().status, RecordingUploadStatus.cancelled);
    });

    test('a second start while uploading is ignored', () async {
      final first = controller().start(request());
      await settle();
      expect(await controller().start(request()), isNull);
      expect(recordings.created, hasLength(1));
      storage.lastUpload.complete();
      expect(await first, 'new-1');
    });

    test('reset after an upload, then a new one gets a new id', () async {
      final first = controller().start(request());
      await settle();
      storage.lastUpload.complete();
      await first;
      controller().reset();
      expect(state(), const RecordingUploadState());

      final second = controller().start(request());
      await settle();
      expect(storage.lastUpload.storagePath, 'recordings/s001/new-2.mp3');
      storage.lastUpload.complete();
      expect(await second, 'new-2');
    });

    test(
      'leaving the screen (dispose) cancels and deletes the document',
      () async {
        final sub = container.listen(
          recordingUploadControllerProvider('row-1'),
          (_, _) {},
        );
        final result = controller().start(request());
        await settle();
        final upload = storage.lastUpload;

        container.dispose();
        expect(upload.cancelCalls, 1);
        expect(await result, isNull);
        expect(recordings.deleted, ['new-1']);
        sub.close();
      },
    );
  });

  group('a two-file recording', () {
    setUp(() => setUpAs(const AuthSession(uid: 't01', role: UserRole.teacher)));

    final sheikhSource = BytesAudioSource(Uint8List.fromList([4, 5, 6]));
    RecordingUploadRequest stems({String sheikhExtension = 'mp3'}) =>
        RecordingUploadRequest(
          studentId: 's001',
          halaqaId: 'halaqa-fajr',
          teacherId: 't01',
          type: RecordingType.official,
          surahNumber: 2,
          ayahFrom: 1,
          ayahTo: 20,
          recordedAt: DateTime(2026, 10, 5, 16),
          source: source,
          fileExtension: 'WAV',
          sheikhSource: sheikhSource,
          sheikhFileExtension: sheikhExtension,
        );

    test('one document, both files side by side, progress of each', () async {
      final result = controller().start(stems());
      await settle();

      final doc = recordings.created.single;
      expect(doc.source, RecordingSource.stems);
      // The server writes the joined mp3 here.
      expect(doc.storagePath, 'recordings/s001/new-1.mp3');
      expect(
        doc.stemPaths,
        const StemPaths(
          student: 'recordings/s001/new-1.student.wav',
          sheikh: 'recordings/s001/new-1.sheikh.mp3',
        ),
      );
      expect(storage.uploads, hasLength(2));
      final [student, sheikh] = storage.uploads;
      expect(student.storagePath, 'recordings/s001/new-1.student.wav');
      expect(student.contentType, 'audio/wav');
      expect(student.source, same(source));
      expect(sheikh.storagePath, 'recordings/s001/new-1.sheikh.mp3');
      expect(sheikh.contentType, 'audio/mpeg');
      expect(sheikh.source, same(sheikhSource));

      student.progress(0.5);
      sheikh.progress(0.25);
      expect(state().progress, 0.375);
      expect(state().stemProgress, (student: 0.5, sheikh: 0.25));
      student.complete();
      expect(state().status, RecordingUploadStatus.uploading);
      sheikh.complete();

      expect(await result, 'new-1');
      expect(state().status, RecordingUploadStatus.done);
      expect(state().stemProgress, isNull);
      expect(recordings.deleted, isEmpty);
    });

    test('one file fails: the other is stopped, the document deleted', () async {
      final result = controller().start(stems());
      await settle();
      final [student, sheikh] = storage.uploads;
      sheikh.fail(const AppException(AppErrorCode.network));

      expect(await result, isNull);
      expect(student.cancelCalls, 1);
      expect(recordings.deleted, ['new-1']);
      expect(state().status, RecordingUploadStatus.failed);
      expect(state().error?.code, AppErrorCode.network);
    });

    test('cancel stops both files', () async {
      final result = controller().start(stems());
      await settle();
      await controller().cancel();

      expect(await result, isNull);
      expect(storage.uploads.map((u) => u.cancelCalls), [1, 1]);
      expect(recordings.deleted, ['new-1']);
      expect(state().status, RecordingUploadStatus.cancelled);
    });

    test('a sheikh file of a type the app refuses: nothing written', () async {
      expect(await controller().start(stems(sheikhExtension: 'flac')), isNull);
      expect(state().error?.code, AppErrorCode.unsupportedFile);
      expect(recordings.created, isEmpty);
      expect(storage.uploads, isEmpty);
    });
  });

  test('one file: a stereo recording, no stemPaths', () async {
    await setUpAs(const AuthSession(uid: 't01', role: UserRole.teacher));
    final result = controller().start(request());
    await settle();
    expect(recordings.created.single.source, RecordingSource.stereo);
    expect(recordings.created.single.stemPaths, isNull);
    expect(storage.uploads, hasLength(1));
    storage.lastUpload.progress(0.5);
    expect(state().stemProgress, isNull);
    storage.lastUpload.complete();
    await result;
  });

  test('a student uploads practice: not reviewed yet', () async {
    await setUpAs(const AuthSession(uid: 's001', role: UserRole.student));
    final result = controller().start(
      request(type: RecordingType.practice, extension: 'webm'),
    );
    await settle();
    final doc = recordings.created.single;
    expect(doc.uploadedBy, 's001');
    expect(doc.type, RecordingType.practice);
    expect(doc.reviewed, isFalse);
    expect(storage.lastUpload.contentType, 'audio/webm');
    storage.lastUpload.complete();
    expect(await result, 'new-1');
  });

  test('signed out: refused, nothing written', () async {
    await setUpAs(null);
    expect(await controller().start(request()), isNull);
    expect(state().error?.code, AppErrorCode.permissionDenied);
    expect(recordings.created, isEmpty);
  });
}
