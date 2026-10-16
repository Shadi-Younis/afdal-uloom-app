import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/utils/ayat_problem.dart';
import 'package:afdal_uloom_tilawat/features/recordings/application/ayat_editor_controller.dart';
import 'package:afdal_uloom_tilawat/features/recordings/application/ayat_editor_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';

void main() {
  late AdminFixture school;
  late ProviderContainer container;

  setUp(() {
    school = AdminFixture();
    container = school.container();
    container.listen(ayatEditorControllerProvider, (_, _) {});
  });

  AyatEditorController editor() =>
      container.read(ayatEditorControllerProvider.notifier);
  AyatEditorState state() => container.read(ayatEditorControllerProvider);

  test('saves what is allowed: ayat, a surah alone, nothing', () async {
    for (final (surah, from, to) in [(67, 1, 5), (67, null, null)]) {
      expect(
        await editor().save(
          recordingId: 'rec-02',
          surah: surah,
          from: from,
          to: to,
        ),
        isTrue,
      );
    }
    expect(
      await editor().save(
        recordingId: 'rec-02',
        surah: null,
        from: null,
        to: null,
      ),
      isTrue,
    );
    expect(school.recordings.ayatCalls, [
      ('rec-02', 67, 1, 5),
      ('rec-02', 67, null, null),
      ('rec-02', null, null, null),
    ]);
    expect(school.recordings.recordings['rec-02']!.surahNumber, isNull);
    expect(state(), const AyatEditorState());
  });

  test('refuses before sending what the upload page refuses', () async {
    final cases = {
      (null, 1, 5): AyatProblem.noSurah,
      (2, 1, null): AyatProblem.oneAyahMissing,
      (2, 21, 20): AyatProblem.notInSurah,
      (112, 1, 9): AyatProblem.notInSurah,
    };
    for (final MapEntry(key: (surah, from, to), value: problem)
        in cases.entries) {
      final saved = await editor().save(
        recordingId: 'rec-02',
        surah: surah,
        from: from,
        to: to,
      );
      expect(saved, isFalse);
      expect(state().problem, problem);
      editor().edited();
      expect(state().problem, isNull);
    }
    expect(school.recordings.ayatCalls, isEmpty);
  });

  test('a server error stays in the state', () async {
    school.recordings.ayatError = const AppException(
      AppErrorCode.permissionDenied,
    );
    final saved = await editor().save(
      recordingId: 'rec-02',
      surah: 1,
      from: null,
      to: null,
    );
    expect(saved, isFalse);
    expect(state().error?.code, AppErrorCode.permissionDenied);
    expect(state().submitting, isFalse);
  });
}
