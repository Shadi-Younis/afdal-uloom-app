import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/fake_user_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  setUpAll(loadBundledFonts);

  const teacher = AuthSession(uid: 't01', role: UserRole.teacher);
  const message = 'لم يعد هذا الحساب فعّالاً. تواصل مع إدارة الدار.';

  late FakeAuthService auth;
  late FakeUserRepository users;

  setUp(() {
    auth = FakeAuthService(initial: teacher, sessionAfterSignIn: teacher);
    users = FakeUserRepository({
      't01': seedUser('t01', 'الشيخ محمود', UserRole.teacher),
    });
  });

  testWidgets('deleted while signed in: back to login with the reason', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpApp(tester, auth: auth, users: users);
    expect(currentPath(tester), '/teacher');

    users.remove('t01');
    await tester.pumpAndSettle();

    expect(auth.signOutCalls, 1);
    expect(currentPath(tester), '/login');
    expect(find.text(message), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled while signed in: the same', (tester) async {
    await pumpApp(tester, auth: auth, users: users);

    users.put(users.users['t01']!.copyWith(disabled: true));
    await tester.pumpAndSettle();

    expect(currentPath(tester), '/login');
    expect(find.text(message), findsOneWidget);
  });

  testWidgets('the reason goes away with the next sign-in attempt', (
    tester,
  ) async {
    await pumpApp(tester, auth: auth, users: users);
    users.put(users.users['t01']!.copyWith(disabled: true));
    await tester.pumpAndSettle();

    // Re-enabled by the admin; the user signs in again.
    users.put(users.users['t01']!.copyWith(disabled: false));
    await tester.enterText(
      find.widgetWithText(TextField, 'اسم المستخدم'),
      't01',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'كلمة السر'),
      'test1234',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'دخول'));
    await tester.pumpAndSettle();

    expect(currentPath(tester), '/teacher');
    expect(auth.signOutCalls, 1);
    expect(find.text(message), findsNothing);
  });

  testWidgets('a normal sign-out shows no reason', (tester) async {
    await pumpApp(tester, auth: auth, users: users);

    await tester.tap(find.byTooltip('تسجيل الخروج'));
    await tester.pumpAndSettle();

    expect(currentPath(tester), '/login');
    expect(find.text(message), findsNothing);
  });
}
