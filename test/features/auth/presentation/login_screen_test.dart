import 'dart:async';

import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/pump_app.dart';

void main() {
  setUpAll(loadBundledFonts);

  late FakeAuthService auth;
  setUp(() => auth = FakeAuthService());

  final usernameField = find.widgetWithText(TextField, 'اسم المستخدم');
  final passwordField = find.widgetWithText(TextField, 'كلمة السر');
  final submit = find.widgetWithText(FilledButton, 'دخول');

  Future<void> pumpLogin(WidgetTester tester) =>
      pumpScreen(tester, const LoginScreen(), auth: auth);

  testWidgets('shows the form and no sign-up or role shortcuts', (
    tester,
  ) async {
    await pumpLogin(tester);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(usernameField, findsOneWidget);
    expect(passwordField, findsOneWidget);
    expect(submit, findsOneWidget);
    expect(find.text('دخول كمدير'), findsNothing);
    expect(find.textContaining('حساب جديد'), findsNothing);
  });

  testWidgets('empty fields show Arabic errors and do not call the server', (
    tester,
  ) async {
    await pumpLogin(tester);
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('أدخل اسم المستخدم'), findsOneWidget);

    await tester.enterText(usernameField, 'shadi');
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('أدخل كلمة السر'), findsOneWidget);
    expect(auth.signInCalls, isEmpty);
  });

  testWidgets('a wrong password shows the Arabic error under the form', (
    tester,
  ) async {
    auth.signInError = const AppException(AppErrorCode.invalidCredentials);
    await pumpLogin(tester);
    await tester.enterText(usernameField, 'shadi');
    await tester.enterText(passwordField, 'wrong');
    await tester.tap(submit);
    await tester.pump();

    final error = find.text('اسم المستخدم أو كلمة السر غير صحيحة');
    expect(error, findsOneWidget);
    expect(
      tester.getRect(error).top,
      greaterThan(tester.getRect(submit).bottom),
    );
  });

  testWidgets('a disabled account shows its own message', (tester) async {
    auth.signInError = const AppException(AppErrorCode.accountDisabled);
    await pumpLogin(tester);
    await tester.enterText(usernameField, 's001');
    await tester.enterText(passwordField, 'test1234');
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('هذا الحساب موقوف، تواصل مع إدارة الدار'), findsOneWidget);
  });

  testWidgets('loading: indicator in the button, form disabled', (
    tester,
  ) async {
    auth.signInGate = Completer();
    await pumpLogin(tester);
    await tester.enterText(usernameField, 'shadi');
    await tester.enterText(passwordField, 'test1234');
    await tester.tap(submit);
    await tester.pump();

    final button = find.byType(FilledButton);
    expect(
      find.descendant(
        of: button,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).enabled,
      isFalse,
    );

    auth.signInGate!.complete();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('username is lower-case and left-to-right', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(usernameField, 'Shadi');
    final field = tester.widget<TextField>(usernameField);
    expect(field.controller!.text, 'shadi');
    expect(field.textDirection, TextDirection.ltr);
    expect(field.autocorrect, isFalse);
  });

  testWidgets('"done" on the password keyboard submits', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(usernameField, 'shadi');
    await tester.enterText(passwordField, 'test1234');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(auth.signInCalls, [('shadi', 'test1234')]);
  });

  testWidgets('the password toggle shows and hides the password', (
    tester,
  ) async {
    await pumpLogin(tester);
    bool obscured() => tester.widget<TextField>(passwordField).obscureText;

    expect(obscured(), isTrue);
    await tester.tap(find.byTooltip('إظهار كلمة السر'));
    await tester.pump();
    expect(obscured(), isFalse);
    await tester.tap(find.byTooltip('إخفاء كلمة السر'));
    await tester.pump();
    expect(obscured(), isTrue);
  });

  testWidgets('fits a 360x640 phone without overflow', (tester) async {
    usePhoneSize(tester);
    await pumpLogin(tester);
    expect(tester.takeException(), isNull);
    expect(tester.getRect(submit).bottom, lessThanOrEqualTo(640));
  });

  testWidgets('scrolls with the keyboard open, no overflow', (tester) async {
    usePhoneSize(tester);
    // A typical phone keyboard: 300 logical pixels.
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    auth.signInError = const AppException(AppErrorCode.network);

    await pumpLogin(tester);
    expect(tester.takeException(), isNull);

    await tester.enterText(usernameField, 'shadi');
    await tester.enterText(passwordField, 'test1234');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    await tester.ensureVisible(find.text('لا يوجد اتصال بالإنترنت'));
    expect(tester.takeException(), isNull);
  });
}
