import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../features/admin/presentation/add_student_screen.dart';
import '../features/admin/presentation/add_teacher_screen.dart';
import '../features/admin/presentation/admin_home_screen.dart';
import '../features/admin/presentation/admin_shell.dart';
import '../features/admin/presentation/create_halaqa_screen.dart';
import '../features/admin/presentation/halaqa_details_screen.dart';
import '../features/admin/presentation/halaqat_screen.dart';
import '../features/admin/presentation/student_details_screen.dart';
import '../features/admin/presentation/students_screen.dart';
import '../features/admin/presentation/teacher_details_screen.dart';
import '../features/admin/presentation/teachers_screen.dart';

/// The admin panel: one branch (with its own back stack) per section of
/// AdminShell's navigation. Every path is under /admin, so the role guard
/// in route_guard.dart covers them all.
///
/// A function, not a shared value: each router needs its own branch
/// navigator keys.
StatefulShellRoute buildAdminRoutes() => StatefulShellRoute.indexedStack(
  builder: (context, state, shell) => AdminShell(navigationShell: shell),
  branches: [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.admin,
          name: AppRoutes.adminName,
          builder: (context, state) => const AdminHomeScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.adminHalaqat,
          name: AppRoutes.adminHalaqatName,
          builder: (context, state) => const HalaqatScreen(),
          routes: [
            GoRoute(
              path: AppRoutes.newSegment,
              name: AppRoutes.adminNewHalaqaName,
              builder: (context, state) => const CreateHalaqaScreen(),
            ),
            GoRoute(
              path: AppRoutes.idPath,
              name: AppRoutes.adminHalaqaName,
              builder: (context, state) =>
                  HalaqaDetailsScreen(halaqaId: _id(state)),
              routes: [
                GoRoute(
                  path: AppRoutes.addStudentSegment,
                  name: AppRoutes.adminHalaqaAddStudentName,
                  builder: (context, state) =>
                      AddStudentScreen(initialHalaqaId: _id(state)),
                ),
                GoRoute(
                  path: AppRoutes.halaqaStudentPath,
                  name: AppRoutes.adminHalaqaStudentName,
                  builder: (context, state) => StudentDetailsScreen(
                    studentId: state.pathParameters[AppRoutes.studentIdParam]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.adminTeachers,
          name: AppRoutes.adminTeachersName,
          builder: (context, state) => const TeachersScreen(),
          routes: [
            GoRoute(
              path: AppRoutes.newSegment,
              name: AppRoutes.adminNewTeacherName,
              builder: (context, state) => const AddTeacherScreen(),
            ),
            GoRoute(
              path: AppRoutes.idPath,
              name: AppRoutes.adminTeacherName,
              builder: (context, state) =>
                  TeacherDetailsScreen(teacherId: _id(state)),
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.adminStudents,
          name: AppRoutes.adminStudentsName,
          builder: (context, state) => StudentsScreen(
            halaqaId: state.uri.queryParameters[AppRoutes.halaqaQuery],
          ),
          routes: [
            GoRoute(
              path: AppRoutes.newSegment,
              name: AppRoutes.adminNewStudentName,
              builder: (context, state) => const AddStudentScreen(),
            ),
            GoRoute(
              path: AppRoutes.idPath,
              name: AppRoutes.adminStudentName,
              builder: (context, state) =>
                  StudentDetailsScreen(studentId: _id(state)),
            ),
          ],
        ),
      ],
    ),
  ],
);

String _id(GoRouterState state) => state.pathParameters[AppRoutes.idParam]!;
