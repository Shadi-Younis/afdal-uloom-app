import 'package:afdal_uloom_tilawat/app/app.dart';
import 'package:afdal_uloom_tilawat/core/models/analysis_status.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_analysis.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_source.dart';
import 'package:afdal_uloom_tilawat/core/models/stem_paths.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/surah_cartouche.dart';
import 'package:afdal_uloom_tilawat/features/recordings/presentation/widgets/recording_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/fake_recording_repository.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/student_fixture.dart';

/// What the teacher and the admin do to an official recording on its
/// screen (Task 12): «تعديل السورة والآيات» and «حذف التسجيل»; and how a
/// recording without a surah shows.
void main() {
  setUpAll(loadBundledFonts);

  const teacher = AuthSession(uid: 't01', role: UserRole.teacher);
  const deleteLabel = 'حذف التسجيل';
  const editLabel = 'تعديل السورة والآيات';

  late StudentFixture fixture;
  setUp(() {
    fixture = StudentFixture();
    // s001's recording sent without surah and ayat.
    fixture.school.recordings.put(
      sampleRecording(
        'rec-bare',
        surahNumber: null,
        ayahFrom: null,
        ayahTo: null,
        recordedAt: DateTime(2026, 10, 11, 16),
      ),
    );
  });

  /// The app as [session], at its home, then the recording [id] pushed on
  /// top (back returns home). [spinning]: a banner's spinner never lets
  /// pumpAndSettle end.
  Future<void> open(
    WidgetTester tester,
    String id,
    AuthSession session, {
    bool spinning = false,
  }) async {
    usePhoneSize(tester);
    fixture.school.auth.emit(session);
    await tester.pumpWidget(
      ProviderScope(overrides: fixture.overrides, child: const AfdalUloomApp()),
    );
    await tester.pumpAndSettle();
    currentRouter(tester).push('/recording/$id');
    if (spinning) {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    } else {
      await tester.pumpAndSettle();
    }
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Finder cartouche(String title) => find.descendant(
    of: find.byType(SurahCartouche),
    matching: find.text(title),
  );

  Finder dialogField(String label) => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(TextField, label),
  );

  Finder saveButton() => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(FilledButton, 'حفظ'),
  );

  group('a recording without a surah', () {
    testWidgets('its screen: «تسجيل» and the date, no ayat line', (
      tester,
    ) async {
      await open(tester, 'rec-bare', studentSession);
      expect(cartouche('تسجيل ١١ أكتوبر ٢٠٢٦'), findsOneWidget);
      expect(find.textContaining('الآية'), findsNothing);
      expect(find.text('رسمي'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the student\'s home lists it the same way', (tester) async {
      usePhoneSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: fixture.overrides,
          child: const AfdalUloomApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        cartouche('تسجيل ١١ أكتوبر ٢٠٢٦'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(cartouche('تسجيل ١١ أكتوبر ٢٠٢٦'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a surah without ayat: the surah, no ayat line', (
      tester,
    ) async {
      fixture.school.recordings.put(
        sampleRecording(
          'rec-bare',
          surahNumber: 67,
          ayahFrom: null,
          ayahTo: null,
        ),
      );
      await open(tester, 'rec-bare', teacher);
      expect(cartouche('سورة الملك'), findsOneWidget);
      // «تعديل السورة والآيات» is there; no line of ayat.
      expect(find.textContaining(RegExp('^الآي')), findsNothing);
    });
  });

  group('«$editLabel»', () {
    testWidgets('the teacher fills in what the upload left out', (
      tester,
    ) async {
      await open(tester, 'rec-bare', teacher);
      await tester.tap(find.text(editLabel));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('السورة والآيات اختيارية: اتركها فارغة إن لم تُعرف.'),
        findsOneWidget,
      );

      await tester.enterText(dialogField('السورة'), '67');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, '٦٧. الملك').last);
      await tester.pumpAndSettle();
      await tester.enterText(dialogField('من آية'), '1');
      await tester.enterText(dialogField('إلى آية'), '٥');
      await tester.pumpAndSettle();
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(fixture.school.recordings.ayatCalls.single, (
        'rec-bare',
        67,
        1,
        5,
      ));
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('تم حفظ السورة والآيات'), findsOneWidget);
      expect(cartouche('سورة الملك'), findsOneWidget);
      expect(find.text('الآيات ١–٥'), findsOneWidget);
    });

    testWidgets('the same checks as the upload page; clearing is allowed', (
      tester,
    ) async {
      await open(tester, 'rec-02', teacher);
      await tester.tap(find.text(editLabel));
      await tester.pumpAndSettle();
      // rec-02 is al-Baqarah 1–20.
      expect(
        tester.widget<TextField>(dialogField('السورة')).controller!.text,
        '٢. البقرة',
      );

      await tester.enterText(dialogField('إلى آية'), '');
      await tester.pumpAndSettle();
      expect(
        find.text('اكتب الآيتين «من» و«إلى» أو اتركهما فارغتين'),
        findsOneWidget,
      );
      await tester.tap(saveButton());
      await tester.pumpAndSettle();
      expect(fixture.school.recordings.ayatCalls, isEmpty);

      await tester.enterText(dialogField('إلى آية'), '300');
      await tester.pumpAndSettle();
      expect(find.text('الآيات ليست في هذه السورة'), findsOneWidget);

      await tester.enterText(dialogField('من آية'), '');
      await tester.enterText(dialogField('إلى آية'), '');
      await tester.pumpAndSettle();
      await tester.tap(saveButton());
      await tester.pumpAndSettle();
      expect(fixture.school.recordings.ayatCalls.single, (
        'rec-02',
        2,
        null,
        null,
      ));
      expect(cartouche('سورة البقرة'), findsOneWidget);
      expect(find.text('الآيات ١–٢٠'), findsNothing);
    });

    testWidgets('ayat without a surah are refused', (tester) async {
      await open(tester, 'rec-bare', adminSession);
      await tester.tap(find.text(editLabel));
      await tester.pumpAndSettle();
      await tester.enterText(dialogField('من آية'), '1');
      await tester.enterText(dialogField('إلى آية'), '3');
      await tester.pumpAndSettle();
      expect(find.text('اختر السورة قبل الآيات'), findsOneWidget);
      await tester.tap(saveButton());
      await tester.pumpAndSettle();
      expect(fixture.school.recordings.ayatCalls, isEmpty);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('not for the student, nor on a practice', (tester) async {
      await open(tester, 'rec-bare', studentSession);
      expect(find.text(editLabel), findsNothing);
      await open(tester, 'rec-20', studentSession);
      expect(find.text(editLabel), findsNothing);
    });
  });

  group('«$deleteLabel»', () {
    Future<void> deleteIt(WidgetTester tester, {bool spinning = false}) async {
      Future<void> settle() => spinning
          ? tester.pump(const Duration(milliseconds: 500))
          : tester.pumpAndSettle();
      // Without a player the page may fit the phone: a drag would only
      // overscroll it.
      if (find.text(deleteLabel).hitTestable().evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          find.text(deleteLabel),
          100,
          scrollable: find
              .descendant(
                of: find.byType(RecordingDetailsView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await settle();
      }
      await tester.tap(find.text(deleteLabel));
      await settle();
      await settle();
      expect(
        find.text('سيُحذف هذا التسجيل وملاحظاته نهائياً ولن يراه الطالب.'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, deleteLabel));
      await settle();
      await settle();
    }

    testWidgets('the teacher: asks, deletes, back to the previous page', (
      tester,
    ) async {
      await open(tester, 'rec-02', teacher);
      await deleteIt(tester);
      expect(fixture.school.recordings.deleted, ['rec-02']);
      expect(currentPath(tester), '/teacher');
      expect(find.text('تم حذف التسجيل'), findsOneWidget);
      expect(find.text('تم حذف هذا العنصر'), findsNothing);
    });

    testWidgets('the admin too', (tester) async {
      await open(tester, 'rec-02', adminSession);
      await deleteIt(tester);
      expect(fixture.school.recordings.deleted, ['rec-02']);
      expect(currentPath(tester), '/admin');
    });

    testWidgets('cancelled: nothing is deleted', (tester) async {
      await open(tester, 'rec-02', teacher);
      await scrollTo(tester, find.text(deleteLabel));
      await tester.tap(find.text(deleteLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(fixture.school.recordings.deleted, isEmpty);
      expect(currentPath(tester), '/recording/rec-02');
    });

    /// s001's al-Baqarah sent as two files, with [analysis] so far.
    void putStems(RecordingAnalysis? analysis) {
      final stems = sampleRecording('rec-stems').copyWith(
        source: RecordingSource.stems,
        storagePath: 'recordings/s001/rec-stems.mp3',
        stemPaths: const StemPaths(
          student: 'recordings/s001/rec-stems.student.wav',
          sheikh: 'recordings/s001/rec-stems.sheikh.wav',
        ),
      );
      fixture.school.recordings.put(
        analysis == null ? stems : stems.copyWith(analysis: analysis),
      );
    }

    testWidgets('also while a two-file recording waits for its files', (
      tester,
    ) async {
      putStems(null);
      await open(tester, 'rec-stems', teacher, spinning: true);
      expect(find.byTooltip('تشغيل'), findsNothing);
      await deleteIt(tester, spinning: true);
      expect(fixture.school.recordings.deleted, ['rec-stems']);
    });

    testWidgets('and after joining its files failed', (tester) async {
      putStems(
        RecordingAnalysis(
          status: AnalysisStatus.failed,
          error: 'stems_length_mismatch',
        ),
      );
      await open(tester, 'rec-stems', teacher);
      expect(find.byTooltip('تشغيل'), findsNothing);
      await deleteIt(tester);
      expect(fixture.school.recordings.deleted, ['rec-stems']);
    });

    testWidgets('not for the student, nor for another teacher', (tester) async {
      await open(tester, 'rec-02', studentSession);
      await scrollTo(tester, find.text('ملاحظات الشيخ'));
      expect(find.text(deleteLabel), findsNothing);
      expect(find.text(editLabel), findsNothing);

      fixture.school.recordings.put(
        sampleRecording('rec-02').copyWith(teacherId: 't02'),
      );
      await open(tester, 'rec-02', teacher);
      expect(find.text(deleteLabel), findsNothing);
      expect(find.text(editLabel), findsNothing);
    });
  });
}
