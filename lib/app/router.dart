import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/application/session_providers.dart';
import '../core/constants/app_routes.dart';
import '../core/models/auth_session.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/student/presentation/student_home_screen.dart';
import '../features/teacher/presentation/teacher_home_screen.dart';
import 'admin_routes.dart';
import 'route_guard.dart';

final routerProvider = Provider<GoRouter>((ref) {
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
