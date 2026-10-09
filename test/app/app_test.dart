import 'package:afdal_uloom_tilawat/core/widgets/islamic/app_back_button.dart';
import 'package:afdal_uloom_tilawat/features/admin/presentation/admin_home_screen.dart';
import 'package:afdal_uloom_tilawat/features/student/presentation/student_home_screen.dart';
import 'package:afdal_uloom_tilawat/features/teacher/presentation/teacher_home_screen.dart';
import 'package:afdal_uloom_tilawat/app/app_colors.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/widgets/common/school_logo.dart';
import 'package:afdal_uloom_tilawat/features/auth/presentation/login_screen.dart';
import 'package:afdal_uloom_tilawat/features/auth/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_user_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  setUpAll(loadBundledFonts);

  final users = FakeUserRepository({
    'shadi': seedUser('shadi', 'شادي', UserRole.admin),
    't01': seedUser('t01', 'الشيخ محمود', UserRole.teacher),
    's001': seedUser('s001', 'أحمد الخطيب', UserRole.student),
  });

  testWidgets('unknown session: splash with the logo, no login flash', (
    tester,
  ) async {
    await pumpApp(
      tester,
      auth: FakeAuthService(initialKnown: false),
      settle: false,
    );
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(SchoolLogo), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('signed out: the Arabic login screen, logo above the title', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, auth: FakeAuthService());

    final title = find.text('تسجيل الدخول');
    final logo = find.bySemanticsLabel(SchoolLogo.semanticLabel);
    expect(title, findsOneWidget);
    expect(logo, findsOneWidget);
    expect(tester.getRect(logo).bottom, lessThan(tester.getRect(title).top));
    semantics.dispose();
  });

  testWidgets('login screen fits a 360x640 phone without overflow', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpApp(tester, auth: FakeAuthService());
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.widgetWithText(FilledButton, 'دخول')).bottom,
      lessThan(640),
    );
  });

  testWidgets('debug build without emulators shows the red PROD banner', (
    tester,
  ) async {
    await pumpApp(tester, auth: FakeAuthService());
    final banner = tester.widget<Banner>(find.byType(Banner));
    expect(banner.message, 'PROD');
    expect(banner.location, BannerLocation.topStart);
    expect(banner.color, AppColors.error);
  });

  for (final (uid, role, home, name) in [
    ('shadi', UserRole.admin, AdminHomeScreen, 'شادي'),
    ('t01', UserRole.teacher, TeacherHomeScreen, 'الشيخ محمود'),
    ('s001', UserRole.student, StudentHomeScreen, 'أحمد الخطيب'),
  ]) {
    testWidgets('signing in as $uid opens $home with the greeting and the '
        'Arabic name; logout returns to login', (tester) async {
      final auth = FakeAuthService(
        sessionAfterSignIn: AuthSession(uid: uid, role: role),
      );
      await pumpApp(tester, auth: auth, users: users);

      await tester.enterText(
        find.widgetWithText(TextField, 'اسم المستخدم'),
        uid,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'كلمة السر'),
        'test1234',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'دخول'));
      await tester.pumpAndSettle();

      expect(find.byType(home), findsOneWidget);
      expect(find.text('السلام عليكم ورحمة الله'), findsOneWidget);
      expect(find.text(name), findsOneWidget);
      expect(find.byType(AppBackButton), findsNothing);

      await tester.tap(find.byTooltip('تسجيل الخروج'));
      await tester.pumpAndSettle();
      expect(auth.signOutCalls, 1);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  }

  testWidgets('a signed-in user starts on their home, never the login', (
    tester,
  ) async {
    await pumpApp(
      tester,
      auth: FakeAuthService(
        initial: const AuthSession(uid: 't01', role: UserRole.teacher),
      ),
      users: users,
    );
    expect(find.byType(TeacherHomeScreen), findsOneWidget);
    expect(find.text('الشيخ محمود'), findsOneWidget);
  });

  testWidgets('another role\'s URL sends the user back to their home', (
    tester,
  ) async {
    await pumpApp(
      tester,
      auth: FakeAuthService(
        initial: const AuthSession(uid: 't01', role: UserRole.teacher),
      ),
      users: users,
    );
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    for (final location in ['/admin', '/student', '/login']) {
      router.go(location);
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/teacher',
        reason: location,
      );
    }
  });

  testWidgets('the name shows an Arabic error with retry if loading fails', (
    tester,
  ) async {
    final failing = FakeUserRepository()
      ..watchError = const AppException(AppErrorCode.network);
    await pumpApp(
      tester,
      auth: FakeAuthService(
        initial: const AuthSession(uid: 's001', role: UserRole.student),
      ),
      users: failing,
    );
    expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
