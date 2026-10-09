import 'package:afdal_uloom_tilawat/core/constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/pump_app.dart';

void main() {
  setUpAll(loadBundledFonts);

  const routes = [
    '/admin',
    '/admin/halaqat',
    '/admin/halaqat/new',
    '/admin/halaqat/halaqa-fajr',
    '/admin/halaqat/halaqa-fajr/add-student',
    '/admin/halaqat/halaqa-fajr/students/s012',
    '/admin/teachers',
    '/admin/teachers/new',
    '/admin/teachers/t01',
    '/admin/students',
    '/admin/students/new',
    '/admin/students/s001',
  ];

  for (final location in routes) {
    testWidgets('$location fits a 360x640 phone, RTL, without overflow', (
      tester,
    ) async {
      usePhoneSize(tester);
      await pumpAdminApp(tester, AdminFixture(), location: location);

      expect(currentPath(tester), location);
      expect(tester.takeException(), isNull);
      expect(
        Directionality.of(tester.element(find.byType(Scaffold).last)),
        TextDirection.rtl,
      );
      // Sections' first pages offer logout; the pages under them go back.
      final root = AppRoutes.parentOf(location) == null;
      expect(
        find.byTooltip('تسجيل الخروج'),
        root ? findsOneWidget : findsNothing,
      );
      expect(find.byTooltip('رجوع'), root ? findsNothing : findsOneWidget);
    });
  }

  testWidgets('home on a phone: greeting, the three counts, shortcuts', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpAdminApp(tester, AdminFixture());

    expect(find.text('السلام عليكم ورحمة الله'), findsOneWidget);
    expect(find.text('شادي'), findsOneWidget);
    // 2 halaqat, 2 active teachers (t03 disabled), 3 active students.
    expect(find.text('٢'), findsNWidgets(2));
    expect(find.text('٣'), findsOneWidget);
    expect(find.text('إضافة طالب'), findsOneWidget);
    expect(find.text('إضافة معلم'), findsOneWidget);
    expect(find.text('إنشاء حلقة'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.text('إنشاء حلقة')).bottom,
      lessThan(640 - kBottomNavigationBarHeight),
    );

    // A card opens its section.
    await tester.tap(find.text('٣'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/admin/students');
  });
}
