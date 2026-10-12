import 'package:afdal_uloom_tilawat/core/application/recording_upload_controller.dart';
import 'package:afdal_uloom_tilawat/core/application/recording_upload_status.dart';
import 'package:afdal_uloom_tilawat/core/application/session_providers.dart';
import 'package:afdal_uloom_tilawat/core/application/student_halaqa_provider.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_type.dart';
import 'package:afdal_uloom_tilawat/features/student/application/practice_recorder_controller.dart';
import 'package:afdal_uloom_tilawat/features/student/application/practice_submit_controller.dart';
import 'package:afdal_uloom_tilawat/features/student/application/recorder_phase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_audio_file_picker.dart';
import '../../../helpers/student_fixture.dart';

void main() {
  late StudentFixture fixture;
  late ProviderContainer container;

  final upload = recordingUploadControllerProvider(
    PracticeSubmitController.uploadKey,
  );

  setUp(() async {
    fixture = StudentFixture();
    container = fixture.container();
    // Shown, as on the page (every provider here is autoDispose).
    container
      ..listen(practiceRecorderControllerProvider, (_, _) {})
      ..listen(practiceSubmitControllerProvider, (_, _) {})
      ..listen(upload, (_, _) {});
    // The profile and its halaqa are loaded, as on the page. (A provider
    // nobody listens to is paused: listened first.)
    container
      ..listen(currentUserProvider, (_, _) {})
      ..listen(studentHalaqaProvider, (_, _) {});
    // The fakes pass session -> profile -> halaqa on in a few steps.
    for (var i = 0; container.read(studentHalaqaProvider).value == null; i++) {
      if (i > 50) fail('the halaqa never loaded');
      await Future<void>.delayed(Duration.zero);
    }
  });

  PracticeSubmitController submit() =>
      container.read(practiceSubmitControllerProvider.notifier);
  PracticeRecorderController recorder() =>
      container.read(practiceRecorderControllerProvider.notifier);

  /// Lets the fakes' futures complete.
  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  void chooseFatiha() => submit()
    ..setSurah(1)
    ..setAyahFrom(1)
    ..setAyahTo(7);

  Future<void> recordTake({
    Duration length = const Duration(seconds: 65),
  }) async {
    await recorder().start();
    fixture.now = fixture.now.add(length);
    recorder().tick();
    await recorder().stop();
  }

  test(
    'without surah and ayat: «اختر السورة والآيات أولاً», nothing sent',
    () async {
      await recordTake();
      expect(await submit().send(), isNull);
      expect(
        container.read(practiceSubmitControllerProvider).showAyatProblem,
        isTrue,
      );
      expect(fixture.school.recordings.created, isEmpty);

      // Editing hides the message again.
      submit().setSurah(1);
      expect(
        container.read(practiceSubmitControllerProvider).showAyatProblem,
        isFalse,
      );
    },
  );

  test('ayat not in the surah are refused like on the upload page', () async {
    submit()
      ..setSurah(112)
      ..setAyahFrom(1)
      ..setAyahTo(9);
    expect(
      container.read(practiceSubmitControllerProvider).hasInvalidAyat,
      isTrue,
    );
    await recordTake();
    expect(await submit().send(), isNull);
    expect(fixture.school.recordings.created, isEmpty);
  });

  test('«إرسال للشيخ»: a practice of his halaqa, unreviewed, uploaded with '
      'progress; then the take is freed', () async {
    chooseFatiha();
    await recordTake();
    final take = container.read(practiceRecorderControllerProvider).take!;

    final sending = submit().send();
    await settle();
    final recording = fixture.school.recordings.created.single;
    expect(recording.type, RecordingType.practice);
    expect(recording.studentId, 's001');
    expect(recording.uploadedBy, 's001');
    expect(recording.halaqaId, 'halaqa-fajr');
    expect(recording.teacherId, 't01');
    expect(recording.reviewed, isFalse);
    expect(recording.unreadFeedback, isFalse);
    expect(
      (recording.surahNumber, recording.ayahFrom, recording.ayahTo),
      (1, 1, 7),
    );
    expect(recording.durationSec, 65);
    expect(recording.recordedAt, fixture.now);
    expect(recording.storagePath, 'recordings/s001/${recording.id}.m4a');

    final file = fixture.school.storage.lastUpload;
    expect(file.contentType, 'audio/mp4');
    expect(file.source, take.source);
    file.progress(0.4);
    expect(container.read(upload).progress, 0.4);
    expect(container.read(upload).isUploading, isTrue);

    file.complete();
    expect(await sending, recording.id);
    expect(container.read(upload).status, RecordingUploadStatus.done);
    expect(
      container.read(practiceRecorderControllerProvider).phase,
      RecorderPhase.ready,
    );
    expect(fixture.recorder.released, [take]);
  });

  test(
    'the upload fails: the document goes, the take stays to retry',
    () async {
      chooseFatiha();
      await recordTake();
      final sending = submit().send();
      await settle();
      fixture.school.storage.lastUpload.fail(
        const AppException(AppErrorCode.network),
      );
      expect(await sending, isNull);

      expect(container.read(upload).status, RecordingUploadStatus.failed);
      expect(container.read(upload).error?.code, AppErrorCode.network);
      expect(fixture.school.recordings.deleted, hasLength(1));
      expect(
        container.read(practiceRecorderControllerProvider).phase,
        RecorderPhase.recorded,
      );
      expect(fixture.recorder.released, isEmpty);

      // Retry: the same take again.
      final retry = submit().send();
      await settle();
      fixture.school.storage.lastUpload.complete();
      expect(await retry, isNotNull);
      expect(fixture.school.storage.uploads, hasLength(2));
    },
  );

  test('cancel: nothing reaches the sheikh, the take stays', () async {
    chooseFatiha();
    await recordTake();
    final sending = submit().send();
    await settle();
    await container.read(upload.notifier).cancel();
    expect(await sending, isNull);
    expect(container.read(upload).status, RecordingUploadStatus.cancelled);
    expect(fixture.school.recordings.deleted, hasLength(1));
    expect(container.read(practiceRecorderControllerProvider).take, isNotNull);
  });

  test('nothing recorded and no file: nothing to send', () async {
    chooseFatiha();
    expect(await submit().send(), isNull);
    expect(fixture.school.recordings.created, isEmpty);
  });

  test(
    '«اختيار ملف»: an audio file is sent instead, without a length',
    () async {
      chooseFatiha();
      fixture.picker.next = [pickedFile('fatiha.mp3')];
      await submit().pickFile();
      expect(
        container.read(practiceSubmitControllerProvider).file?.name,
        'fatiha.mp3',
      );
      expect(
        container.read(practiceSubmitControllerProvider).fileProblem,
        isNull,
      );

      final sending = submit().send();
      await settle();
      final recording = fixture.school.recordings.created.single;
      expect(recording.type, RecordingType.practice);
      expect(recording.storagePath, endsWith('.mp3'));
      expect(recording.durationSec, isNull);
      expect(fixture.school.storage.lastUpload.contentType, 'audio/mpeg');
      fixture.school.storage.lastUpload.complete();
      expect(await sending, recording.id);
      expect(container.read(practiceSubmitControllerProvider).file, isNull);
    },
  );

  test(
    'a file of another type or too large is refused with the reason',
    () async {
      chooseFatiha();
      fixture.picker.next = [pickedFile('notes.pdf')];
      await submit().pickFile();
      expect(
        container.read(practiceSubmitControllerProvider).fileProblem,
        AppErrorCode.unsupportedFile,
      );
      expect(await submit().send(), isNull);

      fixture.picker.next = [
        pickedFile('long.mp3', sizeBytes: 100 * 1024 * 1024),
      ];
      await submit().pickFile();
      expect(
        container.read(practiceSubmitControllerProvider).fileProblem,
        AppErrorCode.fileTooLarge,
      );
      expect(fixture.school.recordings.created, isEmpty);

      submit().clearFile();
      expect(container.read(practiceSubmitControllerProvider).file, isNull);
    },
  );

  test('picking nothing keeps the page as it was', () async {
    await submit().pickFile();
    expect(fixture.picker.calls, 1);
    expect(container.read(practiceSubmitControllerProvider).file, isNull);
  });

  test(
    'a student without a halaqa cannot send (refused before writing)',
    () async {
      fixture.school.users.put(
        fixture.school.users.users['s001']!.copyWith(
          halaqaId: 'no-such-halaqa',
        ),
      );
      await settle();
      chooseFatiha();
      await recordTake();
      expect(await submit().send(), isNull);
      expect(
        container.read(practiceSubmitControllerProvider).error?.code,
        AppErrorCode.permissionDenied,
      );
      expect(fixture.school.recordings.created, isEmpty);
    },
  );
}
