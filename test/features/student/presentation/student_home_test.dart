import 'dart:async';

import 'package:afdal_uloom_tilawat/app/app.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/feedback_note.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_type.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/stat_card.dart';
import 'package:afdal_uloom_tilawat/features/student/presentation/widgets/student_recording_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_recording_repository.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/student_fixture.dart';

/// s001 (أحمد الخطيب) on Monday 2026-10-12: rec-01 official (reviewed),
/// rec-02 official with unread notes (two), rec-20 practice (20 Sep,
/// waiting), and rec-30, a practice of this week (Sunday 11 Oct).
void main() {
  setUpAll(loadBundledFonts);

  late StudentFixture fixture;

  setUp(() {
    fixture = StudentFixture();
    fixture.school.recordings.put(
      sampleRecording(
        'rec-30',
        type: RecordingType.practice,
        surahNumber: 112,
        ayahTo: 4,
        recordedAt: DateTime(2026, 10, 11, 18),
        uploadedBy: 's001',
      ),
    );
  });

  Future<void> pumpStudent(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: fixture.overrides, child: const AfdalUloomApp()),
    );
    await tester.pumpAndSettle();
  }

  String statOf(WidgetTester tester, String label) {
    final card = find.ancestor(
      of: find.descendant(
        of: find.byType(StatCard),
        matching: find.text(label),
      ),
      matching: find.byType(StatCard),
    );
    return tester.widget<StatCard>(card).number.toString();
  }

  Finder cards() => find.byType(StudentRecordingCard, skipOffstage: false);

  List<String> shownIds(WidgetTester tester) => [
    for (final card in tester.widgetList<StudentRecordingCard>(cards()))
      card.recording.id,
  ];

  testWidgets('home on a phone: the counts, «سجّل تدريباً», his recordings '
      'newest first', (tester) async {
    usePhoneSize(tester);
    await pumpStudent(tester);

    expect(currentPath(tester), '/student');
    expect(find.text('أحمد الخطيب'), findsOneWidget);
    expect(statOf(tester, 'تسجيلاتي'), '4');
    expect(statOf(tester, 'ملاحظات جديدة'), '1');
    expect(statOf(tester, 'تدريباتي هذا الأسبوع'), '1');
    expect(find.text('سجّل تدريباً'), findsOneWidget);
    expect(find.text('الكل'), findsOneWidget);
    expect(shownIds(tester), ['rec-30', 'rec-20', 'rec-02', 'rec-01']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360x640: count labels in full (two lines at most), cards '
      'equally tall', (tester) async {
    usePhoneSize(tester);
    await pumpStudent(tester);
    for (final label in ['تسجيلاتي', 'ملاحظات جديدة', 'تدريباتي هذا الأسبوع']) {
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.byType(StatCard), matching: find.text(label)),
      );
      expect(paragraph.didExceedMaxLines, isFalse, reason: label);
    }
    final heights = {
      for (final card in tester.widgetList(find.byType(StatCard)))
        tester.getSize(find.byWidget(card)).height,
    };
    expect(heights, hasLength(1));
  });

  testWidgets('a card: the surah, ayat, the sheikh, unread notes, the count '
      'and «تمت المراجعة»', (tester) async {
    usePhoneSize(tester);
    await pumpStudent(tester);
    final rec02 = find.byWidgetPredicate(
      (w) => w is StudentRecordingCard && w.recording.id == 'rec-02',
      skipOffstage: false,
    );
    await tester.scrollUntilVisible(
      rec02,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    Finder inCard(Finder finder) =>
        find.descendant(of: rec02, matching: finder);
    expect(inCard(find.text('سورة البقرة')), findsOneWidget);
    expect(inCard(find.text('الآيات ١–٢٠')), findsOneWidget);
    expect(inCard(find.text('٨ سبتمبر ٢٠٢٦ · الشيخ محمود')), findsOneWidget);
    expect(inCard(find.text('رسمي')), findsOneWidget);
    expect(inCard(find.text('ملاحظات جديدة')), findsOneWidget);
    expect(inCard(find.text('الملاحظات: ٢')), findsOneWidget);

    final rec01 = find.byWidgetPredicate(
      (w) => w is StudentRecordingCard && w.recording.id == 'rec-01',
      skipOffstage: false,
    );
    await tester.scrollUntilVisible(
      rec01,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(of: rec01, matching: find.text('تمت المراجعة')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: rec01, matching: find.text('ملاحظات جديدة')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the chips filter the list: رسمي, تدريب, الكل', (tester) async {
    usePhoneSize(tester);
    await pumpStudent(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'رسمي'));
    await tester.pumpAndSettle();
    expect(shownIds(tester), ['rec-02', 'rec-01']);

    await tester.tap(find.widgetWithText(ChoiceChip, 'تدريب'));
    await tester.pumpAndSettle();
    expect(shownIds(tester), ['rec-30', 'rec-20']);

    await tester.tap(find.widgetWithText(ChoiceChip, 'الكل'));
    await tester.pumpAndSettle();
    expect(shownIds(tester), hasLength(4));
  });

  testWidgets('a chip with nothing of its type says so', (tester) async {
    for (final id in ['rec-20', 'rec-30']) {
      await fixture.school.recordings.delete(id);
    }
    await pumpStudent(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'تدريب'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد تسجيلات من هذا النوع'), findsOneWidget);
  });

  testWidgets('no recordings at all: the empty state', (tester) async {
    for (final id in [...fixture.school.recordings.recordings.keys]) {
      await fixture.school.recordings.delete(id);
    }
    usePhoneSize(tester);
    await pumpStudent(tester);
    expect(
      find.text('لا توجد تسجيلات بعد. سيظهر هنا ما يرفعه الشيخ وتدريباتك.'),
      findsOneWidget,
    );
    expect(statOf(tester, 'تسجيلاتي'), '0');
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading: the shared spinner; error: the Arabic message and '
      'retry', (tester) async {
    fixture.school.recordings.watchGate = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(overrides: fixture.overrides, child: const AfdalUloomApp()),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.byType(StudentRecordingCard), findsNothing);

    fixture.school.recordings.watchError = const AppException(
      AppErrorCode.network,
    );
    fixture.school.recordings.watchGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('لا يوجد اتصال بالإنترنت'), findsWidgets);

    fixture.school.recordings.watchError = null;
    await tester.tap(find.text('إعادة المحاولة').first);
    await tester.pumpAndSettle();
    expect(find.byType(StudentRecordingCard), findsWidgets);
  });

  testWidgets('a card opens the recording (push), back returns home', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpStudent(tester);
    // Below «حديث اليوم» and the counts on a phone.
    await tester.ensureVisible(find.text('سورة الإخلاص'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('سورة الإخلاص'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/recording/rec-30');
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/student');
  });

  testWidgets('«سجّل تدريباً» opens the recorder (push); the person icon '
      'opens «حسابي»', (tester) async {
    usePhoneSize(tester);
    await pumpStudent(tester);
    await tester.tap(find.text('سجّل تدريباً'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/student/practice');
    expect(find.text('تسجيل تدريب'), findsOneWidget);
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/student');

    await tester.tap(find.byTooltip('حسابي'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/account');
  });

  testWidgets('new notes arrive live: the count and the gold badge', (
    tester,
  ) async {
    await pumpStudent(tester);
    expect(statOf(tester, 'ملاحظات جديدة'), '1');
    fixture.school.recordings.put(
      fixture.school.recordings.recordings['rec-20']!.copyWith(
        unreadFeedback: true,
      ),
    );
    fixture.school.feedback.notes['rec-20'] = [
      FeedbackNote(
        id: 'n1',
        teacherId: 't01',
        note: 'أحسنت',
        createdAt: DateTime(2026, 10, 12),
      ),
    ];
    await tester.pumpAndSettle();
    expect(statOf(tester, 'ملاحظات جديدة'), '2');
  });
}
