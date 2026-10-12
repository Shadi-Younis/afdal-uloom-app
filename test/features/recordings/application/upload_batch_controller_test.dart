import 'package:afdal_uloom_tilawat/core/application/my_students_providers.dart';
import 'package:afdal_uloom_tilawat/core/application/session_providers.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_type.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/providers/clock_provider.dart';
import 'package:afdal_uloom_tilawat/features/recordings/application/upload_batch_controller.dart';
import 'package:afdal_uloom_tilawat/features/recordings/application/upload_batch_state.dart';
import 'package:afdal_uloom_tilawat/features/recordings/application/upload_row.dart';
import 'package:afdal_uloom_tilawat/features/recordings/application/upload_row_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/fake_audio_file_picker.dart';

/// The teacher t01 (حلقة الفجر: s001, s002 and the disabled s012) uploads.
void main() {
  final today = DateTime(2026, 10, 11, 12);
  late AdminFixture school;
  late ProviderContainer container;

  Future<void> start({String? defaultStudentId}) async {
    school = AdminFixture();
    school.auth.emit(const AuthSession(uid: 't01', role: UserRole.teacher));
    container = ProviderContainer.test(
      overrides: [
        ...school.overrides,
        clockProvider.overrideWithValue(() => today),
      ],
    );
    // As on the page: the session, the students and the batch are watched.
    container.listen(sessionProvider, (_, _) {});
    container.listen(myStudentsProvider, (_, _) {});
    container.listen(
      uploadBatchControllerProvider(defaultStudentId),
      (_, _) {},
    );
    await pumpEventQueue();
  }

  UploadBatchController controller([String? defaultStudentId]) =>
      container.read(uploadBatchControllerProvider(defaultStudentId).notifier);
  UploadBatchState state([String? defaultStudentId]) =>
      container.read(uploadBatchControllerProvider(defaultStudentId));
  UploadRow row(int i) => state().rows[i];

  group('adding files', () {
    setUp(start);

    test('the name fills in the student, surah and ayat', () {
      controller().addFiles([pickedFile('S002_002_001-020.mp3')]);
      final added = row(0);
      expect(added.studentId, 's002');
      expect(added.surahNumber, 2);
      expect((added.ayahFrom, added.ayahTo), (1, 20));
      expect(added.recordedAt, today);
      expect(added.isComplete, isTrue);
      expect(added.status, UploadRowStatus.editing);
    });

    test('a code that is not one of my students leaves the student empty', () {
      // s003 is in حلقة العصر (t02).
      controller().addFiles([pickedFile('S003_001_1-7.mp3')]);
      expect(row(0).studentId, isNull);
      expect(row(0).surahNumber, 1);
      expect(row(0).isComplete, isFalse);
    });

    test('a name that says nothing leaves everything empty', () {
      controller().addFiles([pickedFile('Mixdown.mp3')]);
      expect(row(0).studentId, isNull);
      expect(row(0).surahNumber, isNull);
      expect(row(0).canStart, isFalse);
    });

    test('the date in the name is the recording date', () {
      controller().addFiles([pickedFile('S001_2026-10-05_001_1-7.mp3')]);
      expect(row(0).recordedAt, DateTime(2026, 10, 5));
    });

    test('files that can never upload say why', () {
      controller().addFiles([
        pickedFile('notes.txt'),
        pickedFile('S001_001_1-7.mp3', sizeBytes: 100 * 1024 * 1024),
        pickedFile('S001_001_1-7.wav', sizeBytes: 0),
      ]);
      expect(row(0).fileProblem, AppErrorCode.unsupportedFile);
      expect(row(1).fileProblem, AppErrorCode.fileTooLarge);
      expect(row(2).fileProblem, AppErrorCode.unsupportedFile);
      expect(state().rows.any((r) => r.canStart), isFalse);
    });
  });

  test('opened from a student: files without a code are theirs', () async {
    await start(defaultStudentId: 's001');
    controller('s001').addFiles([
      pickedFile('Mixdown.mp3'),
      pickedFile('S002_001_1-7.mp3'),
      pickedFile('S003_001_1-7.mp3'),
    ]);
    final rows = state('s001').rows;
    expect(rows.map((r) => r.studentId), ['s001', 's002', null]);
  });

  group('editing', () {
    setUp(start);

    test('fields can be filled in and cleared', () {
      controller().addFiles([pickedFile('Mixdown.mp3')]);
      final key = row(0).key;
      controller()
        ..setStudent(key, 's001')
        ..setSurah(key, 112)
        ..setAyahFrom(key, 1)
        ..setAyahTo(key, 4)
        ..setRecordedAt(key, DateTime(2026, 10, 9));
      expect(row(0).isComplete, isTrue);
      expect(row(0).recordedAt, DateTime(2026, 10, 9));

      controller().setSurah(key, 1);
      expect(row(0).hasValidAyat, isTrue);
      controller().setAyahTo(key, 8);
      expect(row(0).hasInvalidAyat, isTrue);
      expect(row(0).canStart, isFalse);

      controller().setStudent(key, null);
      expect(row(0).studentId, isNull);
    });

    test('a file is removed', () {
      controller().addFiles([pickedFile('a.mp3'), pickedFile('b.mp3')]);
      controller().remove(row(0).key);
      expect(state().rows.single.file.name, 'b.mp3');
    });
  });

  group('«رفع الكل»', () {
    setUp(start);

    test('uploads complete files one after another, with progress', () async {
      controller().addFiles([
        pickedFile('S001_001_1-7.mp3'),
        pickedFile('Mixdown.mp3'),
        pickedFile('S002_112_1-4.wav'),
      ]);
      final run = controller().uploadAll();
      await pumpEventQueue();

      expect(state().running, isTrue);
      expect(row(0).status, UploadRowStatus.uploading);
      expect(row(1).status, UploadRowStatus.editing);
      expect(row(2).status, UploadRowStatus.waiting);
      expect(school.storage.uploads, hasLength(1));

      school.storage.lastUpload.progress(0.5);
      await pumpEventQueue();
      expect(row(0).progress, 0.5);

      school.storage.lastUpload.complete();
      await pumpEventQueue();
      expect(row(0).status, UploadRowStatus.done);
      expect(row(0).recordingId, 'new-1');
      expect(row(2).status, UploadRowStatus.uploading);
      expect(
        school.storage.lastUpload.storagePath,
        'recordings/s002/new-2.wav',
      );

      school.storage.lastUpload.complete();
      await run;
      expect(state().running, isFalse);
      expect(state().doneCount, 2);
      expect(row(1).status, UploadRowStatus.editing);

      final first = school.recordings.created.first;
      expect(first.type, RecordingType.official);
      expect(first.studentId, 's001');
      expect(first.halaqaId, 'halaqa-fajr');
      expect(first.teacherId, 't01');
      expect(first.uploadedBy, 't01');
      expect(first.reviewed, isFalse);
      expect((first.surahNumber, first.ayahFrom, first.ayahTo), (1, 1, 7));
    });

    test(
      'a failure is shown and the document deleted; retry uploads it',
      () async {
        controller().addFiles([pickedFile('S001_001_1-7.mp3')]);
        final run = controller().uploadAll();
        await pumpEventQueue();
        school.storage.lastUpload.fail(
          const AppException(AppErrorCode.network),
        );
        await run;

        expect(row(0).status, UploadRowStatus.failed);
        expect(row(0).error?.code, AppErrorCode.network);
        expect(school.recordings.deleted, ['new-1']);

        final again = controller().retry(row(0).key);
        await pumpEventQueue();
        expect(row(0).status, UploadRowStatus.uploading);
        expect(row(0).error, isNull);
        school.storage.lastUpload.complete();
        await again;
        expect(row(0).status, UploadRowStatus.done);
        expect(row(0).recordingId, 'new-2');
      },
    );

    test('cancel: the running file stops, a waiting one is skipped', () async {
      controller().addFiles([
        pickedFile('S001_001_1-7.mp3'),
        pickedFile('S002_001_1-7.mp3'),
      ]);
      final run = controller().uploadAll();
      await pumpEventQueue();
      await controller().cancel(row(1).key);
      expect(row(1).status, UploadRowStatus.cancelled);

      await controller().cancel(row(0).key);
      await run;
      expect(row(0).status, UploadRowStatus.cancelled);
      expect(school.storage.uploads, hasLength(1));
      expect(school.recordings.deleted, ['new-1']);
      expect(state().running, isFalse);
      expect(state().canUploadAll, isTrue);
    });

    test('rows being uploaded cannot be edited or removed', () async {
      controller().addFiles([pickedFile('S001_001_1-7.mp3')]);
      final run = controller().uploadAll();
      await pumpEventQueue();
      final key = row(0).key;
      controller()
        ..setSurah(key, 2)
        ..remove(key);
      expect(row(0).surahNumber, 1);
      expect(state().rows, hasLength(1));
      school.storage.lastUpload.complete();
      await run;
    });
  });
}
