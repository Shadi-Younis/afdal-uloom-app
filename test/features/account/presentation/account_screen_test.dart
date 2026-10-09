import 'dart:async';

import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/fake_user_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  setUpAll(loadBundledFonts);

  late AdminFixture school;
  setUp(() => school = AdminFixture());

  Finder field(String label) => find.widgetWithText(TextField, label);
  Finder submitButton() => find.widgetWithText(FilledButton, 'تغيير كلمة السر');

  Future<void> openFromHome(WidgetTester tester) async {
    await pumpAdminApp(tester, school);
    await tester.tap(find.byTooltip('حسابي'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(
    WidgetTester tester,
    String current,
    String next, [
    String? confirm,
  ]) async {
    await tester.enterText(field('كلمة السر الحالية'), current);
    await tester.enterText(field('كلمة السر الجديدة'), next);
    await tester.enterText(field('تأكيد كلمة السر الجديدة'), confirm ?? next);
    await tester.ensureVisible(submitButton());
    await tester.pumpAndSettle();
    await tester.tap(submitButton());
    await tester.pumpAndSettle();
  }

  testWidgets('from the home header: name, username and role; back home', (
    tester,
  ) async {
    usePhoneSize(tester);
    await openFromHome(tester);

    expect(currentPath(tester), '/account');
    expect(find.text('حسابي'), findsOneWidget);
    expect(find.text('شادي'), findsOneWidget);
    expect(find.text('shadi'), findsOneWidget);
    expect(find.text('مدير'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/admin');
  });

  testWidgets('from an admin section page too', (tester) async {
    await pumpAdminApp(tester, school, location: '/admin/students');
    await tester.tap(find.byTooltip('حسابي'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/account');
  });

  testWidgets('a teacher opens it from their home', (tester) async {
    final users = FakeUserRepository({
      't01': seedUser('t01', 'الشيخ محمود', UserRole.teacher),
    });
    await pumpApp(
      tester,
      auth: FakeAuthService(
        initial: const AuthSession(uid: 't01', role: UserRole.teacher),
      ),
      users: users,
    );
    await tester.tap(find.byTooltip('حسابي'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/account');
    expect(find.text('معلم'), findsOneWidget);
    expect(find.text('الشيخ محمود'), findsOneWidget);
  });

  testWidgets('change password: the fields empty, a SnackBar, still in', (
    tester,
  ) async {
    usePhoneSize(tester);
    await openFromHome(tester);
    await fill(tester, 'test1234', 'new-pass-1');

    expect(school.auth.changePasswordCalls.single, ('test1234', 'new-pass-1'));
    expect(find.text('تم تغيير كلمة السر'), findsOneWidget);
    expect(
      tester.widget<TextField>(field('كلمة السر الجديدة')).controller!.text,
      isEmpty,
    );
    expect(currentPath(tester), '/account');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wrong current password: under that field', (tester) async {
    school.auth.changePasswordError = const AppException(
      AppErrorCode.wrongPassword,
    );
    await openFromHome(tester);
    await fill(tester, 'nope', 'new-pass-1');
    expect(find.text('كلمة السر الحالية غير صحيحة'), findsOneWidget);
  });

  testWidgets('checked before sending: length and confirmation', (
    tester,
  ) async {
    await openFromHome(tester);
    await fill(tester, '', '123', '1234');
    expect(find.text('أدخل كلمة السر الحالية'), findsOneWidget);
    expect(find.text('كلمة السر من 6 إلى 64 حرفاً'), findsOneWidget);
    expect(find.text('كلمتا السر غير متطابقتين'), findsOneWidget);
    expect(school.auth.changePasswordCalls, isEmpty);
  });

  testWidgets('a network error: the Arabic message under the form', (
    tester,
  ) async {
    school.auth.changePasswordError = const AppException(AppErrorCode.network);
    await openFromHome(tester);
    await fill(tester, 'test1234', 'new-pass-1');
    expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
  });

  testWidgets('loading while the change runs', (tester) async {
    school.auth.changePasswordGate = Completer();
    await openFromHome(tester);
    await tester.enterText(field('كلمة السر الحالية'), 'test1234');
    await tester.enterText(field('كلمة السر الجديدة'), 'new-pass-1');
    await tester.enterText(field('تأكيد كلمة السر الجديدة'), 'new-pass-1');
    await tester.ensureVisible(submitButton());
    await tester.pumpAndSettle();
    await tester.tap(submitButton());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    school.auth.changePasswordGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('تم تغيير كلمة السر'), findsOneWidget);
  });

  testWidgets('the profile fails to load: the error and a retry', (
    tester,
  ) async {
    school.users.watchError = const AppException(AppErrorCode.network);
    await pumpAdminApp(tester, school, location: '/account');
    expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
