import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_routes.dart';
import '../core/models/auth_session.dart';
import '../core/models/user_role.dart';

/// Each role's home route.
String homeFor(UserRole role) => switch (role) {
  UserRole.admin => AppRoutes.admin,
  UserRole.teacher => AppRoutes.teacher,
  UserRole.student => AppRoutes.student,
};

/// Where the router must go instead of [location], or null to stay.
///
/// - session unknown: the splash screen (no flash of the login screen);
/// - signed out, or the session could not be read: the login screen;
/// - signed in: the role's home, also when another role's URL is typed in.
String? redirectFor(AsyncValue<AuthSession?> session, String location) {
  if (!session.hasValue && !session.hasError) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }
  final current = session.value;
  if (current == null) {
    return location == AppRoutes.login ? null : AppRoutes.login;
  }
  final home = homeFor(current.role);
  final atHome = location == home || location.startsWith('$home/');
  return atHome ? null : home;
}
