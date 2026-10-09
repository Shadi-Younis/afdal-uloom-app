import 'dart:async';

import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/widgets/common/recording_tile.dart';
import 'package:afdal_uloom_tilawat/features/recordings/presentation/recording_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/pump_app.dart';

void main() {
  setUpAll(loadBundledFonts);

  late AdminFixture school;
  setUp(() => school = AdminFixture());

  List<String> listedTitles(WidgetTester tester) => [
    for (final tile in tester.widgetList<ListTile>(
      find.descendant(
        of: find.byType(RecordingTile),
        matching: find.byType(ListTile),
      ),
    ))
      ((tile.title! as Text).data!),
  ];

  Future<void> scrollToRecordings(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('التسجيلات'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('newest first, with title, date, type and the unread dot', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpAdminApp(tester, school, location: '/admin/students/s001');
    await scrollToRecordings(tester);

    expect(listedTitles(tester), [
      'البقرة: الآيات ٤١–٥٠',
      'البقرة: الآيات ١–٢٠',
      'الفاتحة: الآيات ١–٧',
    ]);
    expect(find.text('٢٠ سبتمبر ٢٠٢٦'), findsOneWidget);
    expect(find.text('تدريب'), findsOneWidget);
    expect(find.text('رسمي'), findsNWidgets(2));
    // Only rec-02 has unread feedback.
    expect(find.byTooltip('ملاحظة جديدة لم يقرأها الطالب'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(RecordingTile, 'البقرة: الآيات ١–٢٠'),
        matching: find.byTooltip('ملاحظة جديدة لم يقرأها الطالب'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tap opens the recording; back returns to the student', (
    tester,
  ) async {
    await pumpAdminApp(tester, school, location: '/admin/students/s001');
    await scrollToRecordings(tester);

    await tester.tap(find.text('البقرة: الآيات ١–٢٠'));
    await tester.pumpAndSettle();
    // Pushed on top of the student page (push keeps the page's URI).
    expect(
      currentRouter(tester)
          .routerDelegate
          .currentConfiguration
          .last
          .matchedLocation,
      '/recording/rec-02',
    );
    expect(find.byType(RecordingScreen), findsOneWidget);
    expect(find.byTooltip('تشغيل'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/admin/students/s001');
  });

  testWidgets('a student without recordings: a message', (tester) async {
    await pumpAdminApp(tester, school, location: '/admin/students/s002');
    await scrollToRecordings(tester);
    expect(find.text('لا توجد تسجيلات بعد'), findsOneWidget);
  });

  testWidgets('loading, then an error with a working retry', (tester) async {
    school.recordings.watchError = const AppException(AppErrorCode.network);
    await pumpAdminApp(tester, school, location: '/admin/students/s001');
    await scrollToRecordings(tester);
    expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);

    school.recordings.watchError = null;
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(listedTitles(tester), hasLength(3));
  });

  testWidgets('while the recordings load: a spinner in the section', (
    tester,
  ) async {
    // Settle on another page first: a spinner never settles.
    await pumpAdminApp(tester, school, location: '/admin/students/s002');
    school.recordings.watchGate = Completer<void>();
    currentRouter(tester).go('/admin/students/s001');
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.scrollUntilVisible(
      find.text('التسجيلات'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    school.recordings.watchGate!.complete();
    await tester.pumpAndSettle();
    expect(listedTitles(tester), hasLength(3));
  });
}
