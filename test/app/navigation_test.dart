import 'package:afdal_uloom_tilawat/core/constants/app_routes.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/features/admin/presentation/admin_home_screen.dart';
import 'package:afdal_uloom_tilawat/features/admin/presentation/widgets/rename_halaqa_dialog.dart';
import 'package:afdal_uloom_tilawat/features/student/presentation/student_home_screen.dart';
import 'package:afdal_uloom_tilawat/features/teacher/presentation/teacher_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/admin_fixture.dart';
import '../helpers/fake_auth_service.dart';
import '../helpers/fake_user_repository.dart';
import '../helpers/pump_app.dart';

// Back navigation (task 06): drill-downs are pushed, so back returns to
// where the user was; pages opened from a link go to their parent; a
// section's first page goes to the home tab; home asks before exiting.
void main() {
  setUpAll(loadBundledFonts);

  late AdminFixture school;
  setUp(() => school = AdminFixture());

  /// Android's back button.
  Future<void> systemBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  /// The round back button of the page's top bar.
  Future<void> backButton(WidgetTester tester) async {
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  // Records SystemNavigator.pop (closing the app).
  List<String> watchExit(WidgetTester tester) {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') calls.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return calls;
  }

  group('drill-down: push, then back returns to the page before', () {
    // (start, what to tap, the page it opens).
    const paths = [
      ('/admin/halaqat', 'حلقة الفجر', '/admin/halaqat/halaqa-fajr'),
      (
        '/admin/halaqat/halaqa-fajr',
        'أحمد الخطيب',
        '/admin/halaqat/halaqa-fajr/students/s001',
      ),
      (
        '/admin/halaqat/halaqa-fajr',
        'إضافة طالب',
        '/admin/halaqat/halaqa-fajr/add-student',
      ),
      ('/admin/halaqat', 'إنشاء حلقة', '/admin/halaqat/new'),
      ('/admin/teachers', 'الشيخ محمود', '/admin/teachers/t01'),
      ('/admin/teachers/t01', 'حلقة الفجر', '/admin/halaqat/halaqa-fajr'),
      ('/admin/teachers', 'إضافة معلم', '/admin/teachers/new'),
      ('/admin/students', 'أحمد الخطيب', '/admin/students/s001'),
      ('/admin/students', 'إضافة طالب', '/admin/students/new'),
      ('/admin/students/s001', 'الفاتحة: الآيات ١–٧', '/recording/rec-01'),
      ('/admin', 'إضافة طالب', '/admin/students/new'),
      ('/admin', 'إضافة معلم', '/admin/teachers/new'),
      ('/admin', 'إنشاء حلقة', '/admin/halaqat/new'),
    ];
    for (final (start, tap, opens) in paths) {
      for (final (how, back) in [
        ('back button', backButton),
        ('Android back', systemBack),
      ]) {
        testWidgets('$start -> $opens -> $how -> $start', (tester) async {
          await pumpAdminApp(tester, school, location: start);
          await tapText(tester, tap);
          expect(currentPath(tester), opens);

          await back(tester);
          expect(currentPath(tester), start);
        });
      }
    }
  });

  testWidgets('a created halaqa replaces its form: back goes to the list', (
    tester,
  ) async {
    await pumpAdminApp(tester, school, location: '/admin/halaqat');
    await tapText(tester, 'إنشاء حلقة');
    await tester.enterText(
      find.widgetWithText(TextField, 'اسم الحلقة'),
      'حلقة الضحى',
    );
    await tester.tap(find.text('المعلم'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الشيخ محمود').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'إنشاء'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), startsWith('/admin/halaqat/'));
    expect(currentPath(tester), isNot('/admin/halaqat/new'));

    await backButton(tester);
    expect(currentPath(tester), '/admin/halaqat');
  });

  group('opened from a link (nothing to pop): back goes to the parent', () {
    for (final (link, parent) in [
      ('/recording/rec-02', '/admin'),
      ('/admin/students/s001', '/admin/students'),
      (
        '/admin/halaqat/halaqa-fajr/students/s001',
        '/admin/halaqat/halaqa-fajr',
      ),
    ]) {
      testWidgets('$link -> $parent', (tester) async {
        await pumpAdminApp(tester, school, location: link);
        expect(currentPath(tester), link);
        await backButton(tester);
        expect(currentPath(tester), parent);
      });
    }

    testWidgets('Android back on a linked recording also goes home', (
      tester,
    ) async {
      watchExit(tester);
      await pumpAdminApp(tester, school, location: '/recording/rec-02');
      await systemBack(tester);
      expect(currentPath(tester), '/admin');
    });
  });

  test('every drill-down route has its parent', () {
    const parents = {
      '/admin/halaqat/new': '/admin/halaqat',
      '/admin/halaqat/h1': '/admin/halaqat',
      '/admin/halaqat/h1/add-student': '/admin/halaqat/h1',
      '/admin/halaqat/h1/students/s1': '/admin/halaqat/h1',
      '/admin/teachers/new': '/admin/teachers',
      '/admin/teachers/t1': '/admin/teachers',
      '/admin/students/new': '/admin/students',
      '/admin/students/s1': '/admin/students',
      '/recording/r1': '/',
    };
    for (final MapEntry(key: route, value: parent) in parents.entries) {
      expect(AppRoutes.parentOf(route), parent, reason: route);
    }
    for (final root in [
      '/',
      '/login',
      '/admin',
      '/admin/halaqat',
      '/admin/teachers',
      '/admin/students',
      '/teacher',
      '/student',
    ]) {
      expect(AppRoutes.parentOf(root), isNull, reason: root);
    }
  });

  group('Android back on a root page', () {
    for (final tab in [
      '/admin/halaqat',
      '/admin/teachers',
      '/admin/students',
    ]) {
      testWidgets('$tab (a section) -> the home tab', (tester) async {
        final exits = watchExit(tester);
        await pumpAdminApp(tester, school, location: tab);
        await systemBack(tester);
        expect(currentPath(tester), '/admin');
        expect(find.byType(AdminHomeScreen), findsOneWidget);
        expect(exits, isEmpty);
      });
    }

    testWidgets('admin home: first back warns, a second within 2 s exits', (
      tester,
    ) async {
      final exits = watchExit(tester);
      await pumpAdminApp(tester, school);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('اضغط مرة أخرى للخروج'), findsOneWidget);
      expect(exits, isEmpty);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(exits, ['SystemNavigator.pop']);
    });

    testWidgets('admin home: after 2 s the warning starts over', (
      tester,
    ) async {
      final exits = watchExit(tester);
      await pumpAdminApp(tester, school);
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(seconds: 3));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(exits, isEmpty);
      expect(find.text('اضغط مرة أخرى للخروج'), findsOneWidget);
    });

    for (final (uid, role, home) in [
      ('t01', UserRole.teacher, TeacherHomeScreen),
      ('s001', UserRole.student, StudentHomeScreen),
    ]) {
      testWidgets('$home: double back exits too', (tester) async {
        final exits = watchExit(tester);
        await pumpApp(
          tester,
          auth: FakeAuthService(
            initial: AuthSession(uid: uid, role: role),
          ),
          users: FakeUserRepository({
            't01': seedUser('t01', 'الشيخ محمود', UserRole.teacher),
            's001': seedStudent('s001', 'أحمد الخطيب', 'halaqa-fajr'),
          }),
        );
        expect(find.byType(home), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(find.text('اضغط مرة أخرى للخروج'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(exits, ['SystemNavigator.pop']);
      });
    }
  });

  testWidgets('a dialog closes with Android back, the page stays', (
    tester,
  ) async {
    await pumpAdminApp(tester, school, location: '/admin/halaqat/halaqa-fajr');
    await tapText(tester, 'تغيير الاسم');
    expect(find.byType(RenameHalaqaDialog), findsOneWidget);

    await systemBack(tester);
    expect(find.byType(RenameHalaqaDialog), findsNothing);
    expect(currentPath(tester), '/admin/halaqat/halaqa-fajr');
  });
}
