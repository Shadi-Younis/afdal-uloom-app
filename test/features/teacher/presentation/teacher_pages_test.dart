import 'package:afdal_uloom_tilawat/app/app.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/halaqa.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/providers/clock_provider.dart';
import 'package:afdal_uloom_tilawat/core/widgets/common/recording_tile.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/pump_app.dart';

/// The teacher t01: حلقة الفجر (s001 أحمد الخطيب, s002 عمر الحسن, s012
/// disabled). s001 has rec-01 and rec-02 (official) and rec-20 (practice,
/// recorded 2026-09-20).
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
    expect(statOf(tester, 'تسجيلات هذا الأسبوع'), '1');
    expect(statOf(tester, 'بانتظار المراجعة'), '1');
    expect(find.text('٢'), findsOneWidget);
    expect(find.text('رفع تسجيلات'), findsOneWidget);
    expect(find.text('حلقاتي'), findsOneWidget);
    expect(find.text('حلقة الفجر'), findsOneWidget);
    expect(find.text('عدد الطلاب: ٣'), findsOneWidget);
    expect(find.text('حلقة العصر'), findsNothing);
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
    // Newest first.
    expect(tiles.map((t) => t.recording.id), ['rec-20', 'rec-02', 'rec-01']);
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
