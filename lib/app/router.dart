import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/admin_home_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/student/student_home_screen.dart';
import '../features/teacher/teacher_home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    // TODO: role-based redirect (phase 2.6): signed out -> /login,
    // admin -> /admin, teacher -> /teacher, student -> /student, and block
    // each role from opening another role's routes.
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherHomeScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentHomeScreen(),
      ),
    ],
  );
});
