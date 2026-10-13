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
import 'package:afdal_uloom_tilawat/core/models/recording_source.dart';
import 'package:afdal_uloom_tilawat/core/models/stem_role.dart';

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

  group('two files: the student + the sheikh (Task 11)', () {
    setUp(start);

    const minute = Duration(minutes: 1);

    /// A row of S001's al-Fatiha in two-file mode.
    String stemsRow([String name = 'S001_001_1-7.wav']) {
      controller().addFiles([pickedFile(name)]);
      final key = row(0).key;
      controller().setSource(key, RecordingSource.stems);
      return key;
    }

    test('one file is the default; switching puts the file in a slot', () {
      controller().addFiles([pickedFile('S001_001_1-7 - Sheikh.wav')]);
      expect(row(0).source, RecordingSource.stereo);
      expect(row(0).isComplete, isTrue);

      controller().setSource(row(0).key, RecordingSource.stems);
      expect(row(0).isStems, isTrue);
      // Its name says sheikh.
      expect(row(0).sheikhFile?.name, 'S001_001_1-7 - Sheikh.wav');
      expect(row(0).studentFile, isNull);
      expect(row(0).isComplete, isFalse);

      // Back to one file: the file is still what one-file mode uploads.
      controller().setSource(row(0).key, RecordingSource.stereo);
      expect(row(0).isComplete, isTrue);
    });

    test('no role in the name: the student; the next file the sheikh', () {
      final key = stemsRow();
      expect(row(0).studentFile?.name, 'S001_001_1-7.wav');
      controller().setStems(key, [pickedFile('other.wav')]);
      expect(row(0).sheikhFile?.name, 'other.wav');
      expect(row(0).hasBothStems, isTrue);
      expect(row(0).isComplete, isTrue);
    });

    test('two files dropped on the row: placed by their names', () {
      final key = stemsRow();
      controller().setStems(key, [
        pickedFile('take - SHEIKH.wav'),
        pickedFile('take - talmid.wav'),
      ]);
      expect(row(0).studentFile?.name, 'take - talmid.wav');
      expect(row(0).sheikhFile?.name, 'take - SHEIKH.wav');

      // One name says it: the other file gets the other slot.
      controller().setStems(key, [
        pickedFile('a.wav'),
        pickedFile('صوت الطالب.wav'),
      ]);
      expect(row(0).studentFile?.name, 'صوت الطالب.wav');
      expect(row(0).sheikhFile?.name, 'a.wav');
    });

    test('two files with no names to go by: the order dropped', () {
      final key = stemsRow();
      controller().setStems(key, [pickedFile('1.wav'), pickedFile('2.wav')]);
      expect(row(0).studentFile?.name, '1.wav');
      expect(row(0).sheikhFile?.name, '2.wav');
    });

    test('a file dropped on a zone goes there, whatever its name', () {
      final key = stemsRow();
      controller().setStems(key, [
        pickedFile('x - student.wav'),
      ], into: StemRole.sheikh);
      expect(row(0).sheikhFile?.name, 'x - student.wav');
    });

    test('«تبديل» swaps the files and their lengths', () async {
      school.durations.byName
        ..['a.wav'] = minute
        ..['b.wav'] = minute + const Duration(milliseconds: 400);
      final key = stemsRow('a.wav');
      controller().setStems(key, [pickedFile('b.wav')]);
      await pumpEventQueue();
      expect(row(0).studentDuration, minute);

      controller().swapStems(key);
      expect(row(0).studentFile?.name, 'b.wav');
      expect(row(0).sheikhFile?.name, 'a.wav');
      expect(row(0).sheikhDuration, minute);
    });

    test('either name fills in what is missing', () {
      controller().addFiles([pickedFile('Mixdown.wav')]);
      final key = row(0).key;
      controller().setSource(key, RecordingSource.stems);
      expect(row(0).studentId, isNull);
      controller().setStems(key, [
        pickedFile('S002_2026-10-05_067_1-5 - Sheikh.wav'),
      ]);
      expect(row(0).studentId, 's002');
      expect((row(0).surahNumber, row(0).ayahFrom, row(0).ayahTo), (67, 1, 5));
      expect(row(0).recordedAt, DateTime(2026, 10, 5));
    });

    test('what the teacher filled in stays', () {
      final key = stemsRow();
      controller().setSurah(key, 2);
      controller().setStems(key, [pickedFile('S002_067_1-5 - Sheikh.wav')]);
      expect(row(0).studentId, 's001');
      expect(row(0).surahNumber, 2);
    });

    test(
      'lengths over a second apart: the row says so, cannot start',
      () async {
        school.durations.byName
          ..['S001_001_1-7.wav'] = minute
          ..['sheikh.wav'] = minute + const Duration(milliseconds: 1001);
        final key = stemsRow();
        controller().setStems(key, [pickedFile('sheikh.wav')]);
        await pumpEventQueue();
        expect(row(0).stemsProblem, AppErrorCode.stemsLengthMismatch);
        expect(row(0).canStart, isFalse);

        school.durations.byName['sheikh2.wav'] =
            minute - const Duration(seconds: 1);
        controller().setStems(key, [
          pickedFile('sheikh2.wav'),
        ], into: StemRole.sheikh);
        await pumpEventQueue();
        expect(row(0).stemsProblem, isNull);
        expect(row(0).canStart, isTrue);
      },
    );

    test('an unknown length does not block: the server checks', () async {
      final key = stemsRow();
      controller().setStems(key, [pickedFile('sheikh.ogg')]);
      await pumpEventQueue();
      expect(row(0).sheikhDuration, isNull);
      expect(row(0).canStart, isTrue);
    });

    test('each file must be uploadable on its own', () {
      final key = stemsRow();
      controller().setStems(key, [
        pickedFile('sheikh.wav', sizeBytes: 100 * 1024 * 1024),
      ]);
      expect(row(0).stemsProblem, AppErrorCode.fileTooLarge);
      controller().setStems(key, [
        pickedFile('sheikh.flac'),
      ], into: StemRole.sheikh);
      expect(row(0).stemsProblem, AppErrorCode.unsupportedFile);
      expect(row(0).canStart, isFalse);
    });

    test('both files upload as one recording, each with progress', () async {
      final key = stemsRow('S001_001_1-7 - student.wav');
      controller().setStems(key, [pickedFile('S001_001_1-7 - sheikh.mp3')]);
      final run = controller().uploadAll();
      await pumpEventQueue();

      expect(school.storage.uploads.map((u) => u.storagePath), [
        'recordings/s001/new-1.student.wav',
        'recordings/s001/new-1.sheikh.mp3',
      ]);
      final created = school.recordings.created.single;
      expect(created.source, RecordingSource.stems);
      expect(created.storagePath, 'recordings/s001/new-1.mp3');

      school.storage.uploads[0].progress(1);
      school.storage.uploads[1].progress(0.5);
      await pumpEventQueue();
      expect(row(0).stemProgress, (student: 1.0, sheikh: 0.5));
      expect(row(0).progress, 0.75);

      for (final upload in school.storage.uploads) {
        upload.complete();
      }
      await run;
      expect(row(0).status, UploadRowStatus.done);
      expect(row(0).recordingId, 'new-1');
    });

    test('a row being uploaded cannot change its files', () async {
      final key = stemsRow();
      controller().setStems(key, [pickedFile('sheikh.wav')]);
      final run = controller().uploadAll();
      await pumpEventQueue();
      controller()
        ..swapStems(key)
        ..setSource(key, RecordingSource.stereo)
        ..setStems(key, [pickedFile('other.wav')]);
      expect(row(0).isStems, isTrue);
      expect(row(0).studentFile?.name, 'S001_001_1-7.wav');
      for (final upload in school.storage.uploads) {
        upload.complete();
      }
      await run;
    });
  });
}
