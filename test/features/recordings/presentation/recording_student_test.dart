import 'package:afdal_uloom_tilawat/app/app.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/analysis_status.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/feedback_kind.dart';
import 'package:afdal_uloom_tilawat/core/models/feedback_note.dart';
import 'package:afdal_uloom_tilawat/core/models/halaqa.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_analysis.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/student_fixture.dart';

/// The recording screen as the student s001 sees it, in the whole app
/// (opened from his home): the sheikh named from the halaqa, unread notes
/// cleared on opening, read-only notes, «حذف التدريب» for an unreviewed
/// practice.
void main() {
  setUpAll(loadBundledFonts);

  late StudentFixture fixture;
  setUp(() => fixture = StudentFixture());

  Future<void> open(
    WidgetTester tester,
    String id, {
    AuthSession session = studentSession,
  }) async {
    usePhoneSize(tester);
    fixture.school.auth.emit(session);
    await tester.pumpWidget(
      ProviderScope(overrides: fixture.overrides, child: const AfdalUloomApp()),
    );
    await tester.pumpAndSettle();
    currentRouter(tester).push('/recording/$id');
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('«رُفع بواسطة: الشيخ محمود» and the notes signed «الشيخ '
      'محمود», from the halaqa: no teacher profile is read', (tester) async {
    await open(tester, 'rec-02');
    expect(find.text('رُفع بواسطة: الشيخ محمود'), findsOneWidget);
    await scrollTo(tester, find.text('راجع الآية الخامسة'));
    expect(find.text('الشيخ محمود · ٩ سبتمبر ٢٠٢٦'), findsOneWidget);
    expect(find.text('الشيخ محمود · ١٠ سبتمبر ٢٠٢٦'), findsOneWidget);
    expect(fixture.school.users.watchedUids, isNot(contains('t01')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a halaqa without the name yet: «الشيخ»; a note by another '
      'teacher: «معلم سابق»', (tester) async {
    final fajr = fixture.school.halaqat.halaqat['halaqa-fajr']!;
    fixture.school.halaqat.halaqat['halaqa-fajr'] = fajr.copyWithoutName();
    fixture.school.feedback.notes['rec-02']!.add(
      FeedbackNote(
        id: 'fb-old',
        teacherId: 't-old',
        note: 'من المعلم السابق',
        createdAt: DateTime(2026, 9, 11),
      ),
    );
    await open(tester, 'rec-02');
    expect(find.text('رُفع بواسطة: الشيخ'), findsOneWidget);
    await scrollTo(tester, find.text('من المعلم السابق'));
    expect(find.text('معلم سابق · ١١ سبتمبر ٢٠٢٦'), findsOneWidget);
    expect(find.text('الشيخ · ٩ سبتمبر ٢٠٢٦'), findsOneWidget);
  });

  testWidgets('the halaqa gets its teacher name: the screen follows live', (
    tester,
  ) async {
    final fajr = fixture.school.halaqat.halaqat['halaqa-fajr']!;
    fixture.school.halaqat.halaqat['halaqa-fajr'] = fajr.copyWithoutName();
    await open(tester, 'rec-02');
    expect(find.text('رُفع بواسطة: الشيخ'), findsOneWidget);
    fixture.school.halaqat.put(fajr.copyWith(teacherName: 'محمود'));
    await tester.pumpAndSettle();
    expect(find.text('رُفع بواسطة: الشيخ محمود'), findsOneWidget);
  });

  testWidgets('uploaded by an admin: no uploader line for the student', (
    tester,
  ) async {
    final rec01 = fixture.school.recordings.recordings['rec-01']!;
    fixture.school.recordings.put(rec01.copyWith(uploadedBy: 'shadi'));
    await open(tester, 'rec-01');
    expect(find.textContaining('رُفع بواسطة'), findsNothing);
    expect(fixture.school.users.watchedUids, isNot(contains('shadi')));
  });

  testWidgets('opening a recording with new notes clears them; the home '
      'count follows', (tester) async {
    await open(tester, 'rec-02');
    expect(fixture.school.recordings.readCalls, ['rec-02']);
    expect(
      fixture.school.recordings.recordings['rec-02']!.unreadFeedback,
      isFalse,
    );
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(find.text('ملاحظات جديدة'), findsOneWidget); // the stat label only
  });

  testWidgets('a note arriving while it is open is cleared too', (
    tester,
  ) async {
    await open(tester, 'rec-01');
    expect(fixture.school.recordings.readCalls, isEmpty);
    final rec01 = fixture.school.recordings.recordings['rec-01']!;
    fixture.school.recordings.put(rec01.copyWith(unreadFeedback: true));
    await tester.pumpAndSettle();
    expect(fixture.school.recordings.readCalls, ['rec-01']);
  });

  testWidgets('a refused clear is only a flag: the screen works', (
    tester,
  ) async {
    fixture.school.recordings.markReadError = const AppException(
      AppErrorCode.network,
    );
    await open(tester, 'rec-02');
    expect(find.text('سورة البقرة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the teacher opening it leaves the student\'s flag alone', (
    tester,
  ) async {
    await open(
      tester,
      'rec-02',
      session: const AuthSession(uid: 't01', role: UserRole.teacher),
    );
    expect(find.text('سورة البقرة'), findsOneWidget);
    expect(fixture.school.recordings.readCalls, isEmpty);
  });

  testWidgets('read-only: no note buttons, no «تمت المراجعة», no delete on '
      'an official recording', (tester) async {
    await open(tester, 'rec-02');
    expect(find.text('إضافة ملاحظة هنا'), findsNothing);
    expect(find.text('تمت المراجعة'), findsNothing);
    await scrollTo(tester, find.text('راجع الآية الخامسة'));
    expect(find.byTooltip('حذف الملاحظة'), findsNothing);
    expect(find.byTooltip('تعديل'), findsNothing);
    expect(find.text('حذف التدريب'), findsNothing);
  });

  testWidgets('a practice: no analysis message; the sheikh\'s notes show '
      'the same way', (tester) async {
    final rec20 = fixture.school.recordings.recordings['rec-20']!;
    fixture.school.recordings.put(
      rec20.copyWith(
        analysis: RecordingAnalysis(status: AnalysisStatus.mono),
      ),
    );
    fixture.school.feedback.notes['rec-20'] = [
      FeedbackNote(
        id: 'p1',
        teacherId: 't01',
        note: 'اضبط الوقف',
        kind: FeedbackKind.text,
        atSecond: 4,
        createdAt: DateTime(2026, 9, 21),
      ),
    ];
    await open(tester, 'rec-20');
    expect(find.text('رُفع بواسطة: أحمد الخطيب'), findsOneWidget);
    expect(find.textContaining('قناة الشيخ'), findsNothing);
    expect(find.textContaining('تحليل'), findsNothing);
    await scrollTo(tester, find.text('اضبط الوقف'));
    expect(find.text('الشيخ محمود · ٢١ سبتمبر ٢٠٢٦'), findsOneWidget);
    expect(find.text('عند ٠٠:٠٤'), findsOneWidget);
  });

  testWidgets('«حذف التدريب»: asks, deletes, back home with the message', (
    tester,
  ) async {
    await open(tester, 'rec-20');
    await scrollTo(tester, find.text('حذف التدريب'));
    await tester.tap(find.text('حذف التدريب'));
    await tester.pumpAndSettle();
    expect(
      find.text('سيُحذف هذا التدريب نهائياً ولن يصل إلى الشيخ.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'حذف التدريب'));
    await tester.pumpAndSettle();
    expect(fixture.school.recordings.deleted, ['rec-20']);
    expect(currentPath(tester), '/student');
    expect(find.text('تم حذف التدريب'), findsOneWidget);
    expect(find.text('تم حذف هذا العنصر'), findsNothing);
  });

  testWidgets('«حذف التدريب» cancelled: nothing is deleted', (tester) async {
    await open(tester, 'rec-20');
    await scrollTo(tester, find.text('حذف التدريب'));
    await tester.tap(find.text('حذف التدريب'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(fixture.school.recordings.deleted, isEmpty);
    expect(currentPath(tester), '/recording/rec-20');
  });

  testWidgets('a refused delete shows the Arabic reason and stays', (
    tester,
  ) async {
    fixture.school.recordings.deleteError = const AppException(
      AppErrorCode.permissionDenied,
    );
    await open(tester, 'rec-20');
    await scrollTo(tester, find.text('حذف التدريب'));
    await tester.tap(find.text('حذف التدريب'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'حذف التدريب'));
    await tester.pumpAndSettle();
    expect(find.text('ليست لديك صلاحية لهذا الإجراء.'), findsOneWidget);
    expect(currentPath(tester), '/recording/rec-20');
  });

  testWidgets('no «حذف التدريب» once the sheikh reviewed it, nor for the '
      'teacher', (tester) async {
    final rec20 = fixture.school.recordings.recordings['rec-20']!;
    fixture.school.recordings.put(rec20.copyWith(reviewed: true));
    await open(tester, 'rec-20');
    await scrollTo(tester, find.text('ملاحظات الشيخ'));
    expect(find.text('حذف التدريب'), findsNothing);

    fixture.school.recordings.put(rec20);
    await open(
      tester,
      'rec-20',
      session: const AuthSession(uid: 't01', role: UserRole.teacher),
    );
    await scrollTo(tester, find.text('ملاحظات الشيخ'));
    expect(find.text('حذف التدريب'), findsNothing);
  });
}

extension on Halaqa {
  /// This halaqa as created before Task 10: copyWith cannot clear a field.
  Halaqa copyWithoutName() => Halaqa(id: id, name: name, teacherId: teacherId);
}
