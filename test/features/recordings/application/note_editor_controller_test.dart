import 'dart:async';

import 'package:afdal_uloom_tilawat/core/application/session_providers.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/feedback_kind.dart';
import 'package:afdal_uloom_tilawat/core/models/feedback_note.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/features/recordings/application/note_editor_controller.dart';
import 'package:afdal_uloom_tilawat/features/recordings/application/note_editor_state.dart';
import 'package:afdal_uloom_tilawat/features/recordings/application/recording_manage_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';

void main() {
  late AdminFixture school;
  late ProviderContainer container;

  setUp(() async {
    school = AdminFixture();
    school.auth.emit(const AuthSession(uid: 't01', role: UserRole.teacher));
    container = school.container();
    // In the app the router keeps the session alive.
    container.listen(sessionProvider, (_, _) {});
    container.listen(noteEditorControllerProvider, (_, _) {});
    container.listen(recordingManageControllerProvider('rec-02'), (_, _) {});
    // The session is a stream: let it deliver.
    await pumpEventQueue();
  });

  NoteEditorController editor() =>
      container.read(noteEditorControllerProvider.notifier);
  NoteEditorState state() => container.read(noteEditorControllerProvider);

  final marker = FeedbackNote(
    id: 'v1',
    teacherId: 't01',
    note: '',
    kind: FeedbackKind.voice,
    atSecond: 5,
    endSecond: 9,
    createdAt: DateTime(2026, 9, 9),
  );

  group('add', () {
    test('a written note of the signed-in teacher, trimmed', () async {
      final saved = await editor().add(
        recordingId: 'rec-02',
        atSecond: 42,
        text: '  انتبه للمدّ ',
        rating: 4,
      );
      expect(saved, isTrue);
      final (id, note) = school.feedback.added.single;
      expect(id, 'rec-02');
      expect(note.teacherId, 't01');
      expect(note.kind, FeedbackKind.text);
      expect(note.note, 'انتبه للمدّ');
      expect(note.atSecond, 42);
      expect(note.rating, 4);
      expect(state(), const NoteEditorState());
    });

    test('empty or too long text is refused before sending', () async {
      final empty = await editor().add(
        recordingId: 'rec-02',
        atSecond: 1,
        text: '   ',
      );
      expect(empty, isFalse);
      expect(state().problem, NoteProblem.required);
      editor().edited();
      expect(state().problem, isNull);

      final long = await editor().add(
        recordingId: 'rec-02',
        atSecond: 1,
        text: List.filled(2001, 'x').join(),
      );
      expect(long, isFalse);
      expect(state().problem, NoteProblem.tooLong);
      expect(school.feedback.added, isEmpty);
    });

    test('a server error stays in the state', () async {
      school.feedback.writeError = const AppException(AppErrorCode.network);
      final saved = await editor().add(
        recordingId: 'rec-02',
        atSecond: 1,
        text: 'x',
      );
      expect(saved, isFalse);
      expect(state().error?.code, AppErrorCode.network);
      expect(state().submitting, isFalse);
    });

    test('submitting while sending; a second submit is ignored', () async {
      school.feedback.writeGate = Completer<void>();
      final first = editor().add(recordingId: 'rec-02', atSecond: 1, text: 'a');
      expect(state().submitting, isTrue);
      final second = await editor().add(
        recordingId: 'rec-02',
        atSecond: 1,
        text: 'b',
      );
      expect(second, isFalse);
      school.feedback.writeGate!.complete();
      expect(await first, isTrue);
      expect(school.feedback.added, hasLength(1));
    });
  });

  test(
    'edit: a voice marker may keep empty text, a written note not',
    () async {
      final voice = await editor().edit(
        recordingId: 'rec-02',
        note: marker,
        text: '  ',
        rating: 2,
      );
      expect(voice, isTrue);
      expect(school.feedback.updated.single, ('rec-02', 'v1', '', 2));

      final written = school.feedback.notes['rec-02']!.first;
      final emptied = await editor().edit(
        recordingId: 'rec-02',
        note: written,
        text: '',
      );
      expect(emptied, isFalse);
      expect(state().problem, NoteProblem.required);
    },
  );

  group('RecordingManageController', () {
    RecordingManageController manage() =>
        container.read(recordingManageControllerProvider('rec-02').notifier);

    test('deletes a note and toggles reviewed', () async {
      expect(await manage().deleteNote('fb-02'), isTrue);
      expect(school.feedback.deleted.single, ('rec-02', 'fb-02'));
      expect(await manage().setReviewed(reviewed: false), isTrue);
      expect(school.recordings.reviewedCalls.single, ('rec-02', false));
    });

    test('an error is kept for the screen', () async {
      school.feedback.writeError = const AppException(
        AppErrorCode.permissionDenied,
      );
      expect(await manage().deleteNote('fb-02'), isFalse);
      final state = container.read(recordingManageControllerProvider('rec-02'));
      expect(
        (state.error! as AppException).code,
        AppErrorCode.permissionDenied,
      );
    });
  });
}
