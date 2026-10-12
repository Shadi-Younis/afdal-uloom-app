import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/application/session_providers.dart';
import '../core/constants/app_routes.dart';
import '../core/models/auth_session.dart';
import '../features/account/presentation/account_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/recordings/presentation/recording_screen.dart';
import '../features/recordings/presentation/upload_screen.dart';
import '../features/student/presentation/student_home_screen.dart';
import '../features/teacher/presentation/teacher_halaqa_screen.dart';
import '../features/teacher/presentation/teacher_home_screen.dart';
import '../features/teacher/presentation/teacher_review_screen.dart';
import '../features/teacher/presentation/teacher_student_screen.dart';
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
      // Before the shell: a full page without the admin's navigation bar.
      GoRoute(
        path: AppRoutes.adminUploadPath,
        name: AppRoutes.adminUploadName,
        builder: (context, state) => UploadScreen(
          studentId: state.uri.queryParameters[AppRoutes.studentQuery],
        ),
      ),
      buildAdminRoutes(),
      GoRoute(
        path: AppRoutes.teacher,
        name: AppRoutes.teacherName,
        builder: (context, state) => const TeacherHomeScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.uploadSegment,
            name: AppRoutes.teacherUploadName,
            builder: (context, state) => UploadScreen(
              studentId: state.uri.queryParameters[AppRoutes.studentQuery],
            ),
          ),
          GoRoute(
            path: AppRoutes.reviewSegment,
            name: AppRoutes.teacherReviewName,
            builder: (context, state) => const TeacherReviewScreen(),
          ),
          GoRoute(
            path: AppRoutes.teacherHalaqaPath,
            name: AppRoutes.teacherHalaqaName,
            builder: (context, state) => TeacherHalaqaScreen(
              halaqaId: state.pathParameters[AppRoutes.idParam]!,
            ),
            routes: [
              GoRoute(
                path: AppRoutes.halaqaStudentPath,
                name: AppRoutes.teacherStudentName,
                builder: (context, state) => TeacherStudentScreen(
                  halaqaId: state.pathParameters[AppRoutes.idParam]!,
                  studentId: state.pathParameters[AppRoutes.studentIdParam]!,
                ),
              ),
            ],
          ),
        ],
      ),
      // Outside the role shells: every role opens it, on top of its page.
      GoRoute(
        path: AppRoutes.recordingPath,
        name: AppRoutes.recordingName,
        builder: (context, state) => RecordingScreen(
          recordingId: state.pathParameters[AppRoutes.idParam]!,
        ),
      ),
      // Outside the role shells too: every role's own account page.
      GoRoute(
        path: AppRoutes.account,
        name: AppRoutes.accountName,
        builder: (context, state) => const AccountScreen(),
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
