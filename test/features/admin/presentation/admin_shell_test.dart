import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/features/admin/presentation/admin_home_screen.dart';
import 'package:afdal_uloom_tilawat/features/admin/presentation/halaqat_screen.dart';
import 'package:afdal_uloom_tilawat/features/admin/presentation/students_screen.dart';
import 'package:afdal_uloom_tilawat/features/admin/presentation/teachers_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/pump_app.dart';

void main() {
  setUpAll(loadBundledFonts);

  late AdminFixture school;
  setUp(() => school = AdminFixture());

  Finder appBarTitle(String title) =>
      find.descendant(of: find.byType(AppBar), matching: find.text(title));

  testWidgets('phone: bottom navigation bar with the four sections', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpAdminApp(tester, school);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    for (final label in ['الرئيسية', 'الحلقات', 'المعلمون', 'الطلاب']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
    expect(find.byType(AdminHomeScreen), findsOneWidget);
  });

  testWidgets('phone: each destination opens its section, with logout', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpAdminApp(tester, school);
    Finder destination(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );

    for (final (label, screen, path) in [
      ('الحلقات', HalaqatScreen, '/admin/halaqat'),
      ('المعلمون', TeachersScreen, '/admin/teachers'),
      ('الطلاب', StudentsScreen, '/admin/students'),
      ('الرئيسية', AdminHomeScreen, '/admin'),
    ]) {
      await tester.tap(destination(label));
      await tester.pumpAndSettle();
      expect(find.byType(screen), findsOneWidget, reason: label);
      expect(currentPath(tester), path);
      expect(find.byTooltip('تسجيل الخروج'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('wide: a navigation rail on the right (RTL), no bottom bar', (
    tester,
  ) async {
    useWideSize(tester);
    await pumpAdminApp(tester, school);

    expect(find.byType(NavigationBar), findsNothing);
    final rail = find.byType(NavigationRail);
    expect(rail, findsOneWidget);
    expect(tester.getRect(rail).right, 1280);
    expect(tester.getRect(rail).left, greaterThan(1280 / 2));

    await tester.tap(
      find.descendant(of: rail, matching: find.text('المعلمون')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TeachersScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('each section keeps its own page when switching', (tester) async {
    usePhoneSize(tester);
    await pumpAdminApp(tester, school, location: '/admin/halaqat/halaqa-fajr');
    expect(appBarTitle('حلقة الفجر'), findsOneWidget);

    await tester.tap(find.text('الطلاب').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('الحلقات').last);
    await tester.pumpAndSettle();
    expect(appBarTitle('حلقة الفجر'), findsOneWidget);

    // Tapping the current section again returns to its first page.
    await tester.tap(find.text('الحلقات').last);
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/admin/halaqat');
  });

  testWidgets('a teacher typing an /admin/* URL is sent home', (tester) async {
    final teacher = FakeAuthService(
      initial: const AuthSession(uid: 't01', role: UserRole.teacher),
    );
    await pumpApp(
      tester,
      auth: teacher,
      users: school.users,
      halaqat: school.halaqat,
    );
    for (final location in [
      '/admin',
      '/admin/halaqat',
      '/admin/students/s001',
      '/admin/teachers/new',
    ]) {
      currentRouter(tester).go(location);
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/teacher', reason: location);
    }
  });
}
