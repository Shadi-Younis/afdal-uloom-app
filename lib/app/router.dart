import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../features/admin/presentation/admin_home_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/student/presentation/student_home_screen.dart';
import '../features/teacher/presentation/teacher_home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    // TODO: role-based redirect (phase 2.6): signed out -> /login,
    // admin -> /admin, teacher -> /teacher, student -> /student, and block
    // each role from opening another role's routes.
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        name: AppRoutes.adminName,
        builder: (context, state) => const AdminHomeScreen(),
      ),
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
});
