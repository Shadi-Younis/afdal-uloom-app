import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/application/session_providers.dart';
import '../core/constants/app_routes.dart';
import '../core/models/auth_session.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/recordings/presentation/recording_screen.dart';
import '../features/student/presentation/student_home_screen.dart';
import '../features/teacher/presentation/teacher_home_screen.dart';
import 'admin_routes.dart';
import 'route_guard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Pages opened with push (every drill-down) get their own URL and browser
  // history entry, so the browser's back / forward follow the app's back,
  // and a refresh reopens the same page. Every route is deep-linkable, so
  // the URL of the top page is always valid.
  GoRouter.optionURLReflectsImperativeAPIs = true;

  // The router is built once; session changes only re-run its redirect.
  final session = ValueNotifier<AsyncValue<AuthSession?>>(
    ref.read(sessionProvider),
  );
  ref.listen(sessionProvider, (_, next) => session.value = next);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: session,
    redirect: (context, state) =>
        redirectFor(session.value, state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      buildAdminRoutes(),
      GoRoute(
        path: AppRoutes.teacher,
        name: AppRoutes.teacherName,
        builder: (context, state) => const TeacherHomeScreen(),
      ),
      // Outside the role shells: every role opens it, on top of its page.
      GoRoute(
        path: AppRoutes.recordingPath,
        name: AppRoutes.recordingName,
        builder: (context, state) => RecordingScreen(
          recordingId: state.pathParameters[AppRoutes.idParam]!,
        ),
      ),
      GoRoute(
        path: AppRoutes.student,
        name: AppRoutes.studentName,
        builder: (context, state) => const StudentHomeScreen(),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
});
