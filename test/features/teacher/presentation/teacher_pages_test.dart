import 'package:afdal_uloom_tilawat/app/app.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/halaqa.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/providers/clock_provider.dart';
import 'package:afdal_uloom_tilawat/core/widgets/common/recording_tile.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/fake_recording_repository.dart';
import '../../../helpers/pump_app.dart';

/// The teacher t01: حلقة الفجر (s001 أحمد الخطيب, s002 عمر الحسن, s012
/// disabled). s001 has rec-01 and rec-02 (official) and rec-20 (practice,
/// recorded 2026-09-20: his own, the teacher never sees it); s002 has
/// rec-21 (official, reviewed, recorded 2026-09-20).
void main() {
  setUpAll(loadBundledFonts);

  const teacher = AuthSession(uid: 't01', role: UserRole.teacher);
  // Monday 2026-09-21: the school week began on Saturday 2026-09-19.
  final now = DateTime(2026, 9, 21, 10);

  late AdminFixture school;

  setUp(() {
    school = AdminFixture();
    school.auth.emit(teacher);
    // rec-02 waits for its review.
    school.recordings.put(
      school.recordings.recordings['rec-02']!.copyWith(reviewed: false),
    );
    school.recordings.put(
      sampleRecording(
        'rec-21',
        studentId: 's002',
        surahNumber: 112,
        ayahTo: 4,
        recordedAt: DateTime(2026, 9, 20, 16),
      ),
    );
  });

  Future<void> pumpTeacher(WidgetTester tester, {String? location}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...school.overrides,
          clockProvider.overrideWithValue(() => now),
        ],
        child: const AfdalUloomApp(),
      ),
    );
    await tester.pumpAndSettle();
    if (location != null) {
      currentRouter(tester).go(location);
      await tester.pumpAndSettle();
    }
  }

  String statOf(WidgetTester tester, String label) {
    final card = find.ancestor(
      of: find.text(label),
      matching: find.byType(StatCard),
    );
    return tester.widget<StatCard>(card).number.toString();
  }

  testWidgets('home: the counts, «رفع تسجيلات» and his halaqat only', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpTeacher(tester);

    expect(currentPath(tester), '/teacher');
    // s012 is disabled: two active students.
    expect(statOf(tester, 'طلابي'), '2');
    // rec-21; rec-20 is a practice: the student's own (Task 12).
    expect(statOf(tester, 'تسجيلات هذا الأسبوع'), '1');
    // Only rec-02 waits for him; never a practice.
    expect(statOf(tester, 'بانتظار المراجعة'), '1');
    expect(find.text('٢'), findsOneWidget);
    expect(find.text('١'), findsNWidgets(2));
    expect(find.text('رفع تسجيلات'), findsOneWidget);
    expect(find.text('حلقاتي'), findsOneWidget);
    expect(find.text('حلقة الفجر'), findsOneWidget);
    expect(find.text('عدد الطلاب: ٣'), findsOneWidget);
    expect(find.text('حلقة العصر'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('«بانتظار المراجعة» opens his queue: official recordings, '
      'oldest first, with the student; no practice (Task 12)', (tester) async {
    usePhoneSize(tester);
    school.recordings.put(
      school.recordings.recordings['rec-21']!.copyWith(reviewed: false),
    );
    await pumpTeacher(tester);

    await tester.tap(find.text('بانتظار المراجعة'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/teacher/review');
    final tiles = find.byType(RecordingTile);
    expect(tiles, findsNWidgets(2));
    // Oldest createdAt first: rec-02 (8 Sep), then rec-21 (20 Sep).
    final first = tester.widget<RecordingTile>(tiles.at(0)).recording;
    final second = tester.widget<RecordingTile>(tiles.at(1)).recording;
    expect([first.id, second.id], ['rec-02', 'rec-21']);
    expect(find.text('رسمي'), findsNWidgets(2));
    expect(find.text('تدريب'), findsNothing);
    expect(find.textContaining('أحمد الخطيب ·'), findsOneWidget);
    expect(find.textContaining('عمر الحسن ·'), findsOneWidget);
    expect(find.text('بانتظار المراجعة'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.textContaining('عمر الحسن ·'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/recording/rec-21');
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/teacher/review');
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/teacher');
  });

  testWidgets('the queue: a reviewed recording leaves it; empty state', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpTeacher(tester, location: '/teacher/review');
    expect(find.byType(RecordingTile), findsOneWidget);

    await school.recordings.setReviewed('rec-02', reviewed: true);
    await tester.pumpAndSettle();
    expect(
      find.text('لا توجد تسجيلات بانتظار المراجعة. بارك الله فيك.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the queue opened from a link: back goes to the home', (
    tester,
  ) async {
    await pumpTeacher(tester, location: '/teacher/review');
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/teacher');
  });

  testWidgets('360x640: every count label shows in full, cards equally tall', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpTeacher(tester);

    for (final label in ['طلابي', 'تسجيلات هذا الأسبوع', 'بانتظار المراجعة']) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      expect(paragraph.didExceedMaxLines, isFalse, reason: label);
    }
    final heights = {
      for (final card in tester.widgetList(find.byType(StatCard)))
        tester.getSize(find.byWidget(card)).height,
    };
    expect(heights, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('halaqa → its students → a student → a recording, and back', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpTeacher(tester);

    await tester.tap(find.text('حلقة الفجر'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/teacher/halaqat/halaqa-fajr');
    expect(find.text('أحمد الخطيب'), findsOneWidget);
    expect(find.text('عمر الحسن'), findsOneWidget);
    expect(find.text('موقوف'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('أحمد الخطيب'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/teacher/halaqat/halaqa-fajr/students/s001');
    expect(find.text('S001'), findsOneWidget);
    expect(find.text('حلقة الفجر'), findsOneWidget);
    expect(find.text('رفع تسجيل لهذا الطالب'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byType(RecordingTile).last,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final tiles = tester
        .widgetList<RecordingTile>(find.byType(RecordingTile))
        .toList();
    // Newest first; rec-20 is his practice: not the teacher's to see.
    expect(tiles.map((t) => t.recording.id), ['rec-02', 'rec-01']);
    expect(find.text('تدريب'), findsNothing);
    // rec-02 has one note about a moment (00:12) and waits for review.
    expect(find.textContaining('الملاحظات: ١'), findsOneWidget);
    expect(find.text('بانتظار المراجعة'), findsWidgets);
    expect(find.text('تمت مراجعته'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.textContaining('الملاحظات: ١'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/recording/rec-02');

    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/teacher/halaqat/halaqa-fajr/students/s001');
  });

  testWidgets('«رفع تسجيلات» and the student\'s upload open the upload page', (
    tester,
  ) async {
    await pumpTeacher(tester);
    await tester.tap(find.text('رفع تسجيلات'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/teacher/upload');
    expect(find.text('اختيار ملفات'), findsOneWidget);

    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/teacher');

    currentRouter(tester).go('/teacher/halaqat/halaqa-fajr/students/s001');
    await tester.pumpAndSettle();
    await tester.tap(find.text('رفع تسجيل لهذا الطالب'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/teacher/upload');
  });

  testWidgets('a teacher without halaqat: a message', (tester) async {
    school.halaqat.put(
      const Halaqa(id: 'halaqa-fajr', name: 'حلقة الفجر', teacherId: 't02'),
    );
    await pumpTeacher(tester);
    expect(
      find.text('لا توجد لك حلقة بعد. تواصل مع إدارة الدار.'),
      findsOneWidget,
    );
    expect(statOf(tester, 'طلابي'), '0');
  });

  testWidgets('a halaqa opened from a link: back goes home', (tester) async {
    await pumpTeacher(tester, location: '/teacher/halaqat/halaqa-fajr');
    expect(find.text('أحمد الخطيب'), findsOneWidget);
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/teacher');
  });

  testWidgets('a student page fits a 360x640 phone', (tester) async {
    usePhoneSize(tester);
    await pumpTeacher(
      tester,
      location: '/teacher/halaqat/halaqa-fajr/students/s001',
    );
    expect(find.text('أحمد الخطيب'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
