import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/pump_app.dart';

/// Details pages whose item is deleted while they are open (by another
/// device, or from another tab of the app).
void main() {
  setUpAll(loadBundledFonts);

  const deleted = 'تم حذف هذا العنصر';
  const notFound = 'العنصر المطلوب غير موجود.';

  late AdminFixture school;
  setUp(() => school = AdminFixture());

  Future<void> tapNav(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a halaqa: back to the halaqat with the message', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpAdminApp(tester, school, location: '/admin/halaqat');
    await tester.tap(find.text('حلقة العصر'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/admin/halaqat/halaqa-asr');

    school.halaqat.remove('halaqa-asr');
    await tester.pumpAndSettle();

    expect(currentPath(tester), '/admin/halaqat');
    expect(find.text(deleted), findsOneWidget);
    expect(find.text(notFound), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a teacher opened from a link: to the teachers list', (
    tester,
  ) async {
    await pumpAdminApp(tester, school, location: '/admin/teachers/t03');
    expect(find.text('الشيخ سعيد'), findsWidgets);

    school.users.remove('t03');
    await tester.pumpAndSettle();

    expect(currentPath(tester), '/admin/teachers');
    expect(find.text(deleted), findsOneWidget);
  });

  testWidgets('a student of a halaqa: back to that halaqa', (tester) async {
    await pumpAdminApp(tester, school, location: '/admin/halaqat/halaqa-fajr');
    await tester.tap(find.text('عمر الحسن'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/admin/halaqat/halaqa-fajr/students/s002');

    school.users.remove('s002');
    await tester.pumpAndSettle();

    expect(currentPath(tester), '/admin/halaqat/halaqa-fajr');
    expect(find.text(deleted), findsOneWidget);
  });

  testWidgets('in another tab: nothing moves until that tab is shown', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpAdminApp(tester, school, location: '/admin/students');
    await tester.tap(find.text('عمر الحسن'));
    await tester.pumpAndSettle();
    await tapNav(tester, 'الحلقات');
    expect(currentPath(tester), '/admin/halaqat');

    school.users.remove('s002');
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/admin/halaqat');
    expect(find.text(deleted), findsNothing);

    await tapNav(tester, 'الطلاب');
    expect(currentPath(tester), '/admin/students');
    expect(find.text(deleted), findsOneWidget);
    expect(find.text('عمر الحسن'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a recording: back to the student page it was opened from', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpAdminApp(tester, school, location: '/admin/students/s001');
    await tester.ensureVisible(find.text('البقرة: الآيات ١–٢٠'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('البقرة: الآيات ١–٢٠'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/recording/rec-02');

    await school.recordings.delete('rec-02');
    await tester.pumpAndSettle();

    expect(currentPath(tester), '/admin/students/s001');
    expect(find.text(deleted), findsOneWidget);
    expect(find.text('البقرة: الآيات ١–٢٠'), findsNothing);
  });

  group('never existed: the not-found state, no message', () {
    for (final location in [
      '/admin/halaqat/no-such-halaqa',
      '/admin/teachers/no-such-teacher',
      '/admin/students/no-such-student',
      '/recording/no-such-recording',
    ]) {
      testWidgets(location, (tester) async {
        await pumpAdminApp(tester, school, location: location);
        expect(currentPath(tester), location);
        expect(find.text(notFound), findsOneWidget);
        expect(find.text(deleted), findsNothing);
      });
    }
  });
}
