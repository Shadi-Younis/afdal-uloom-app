import 'package:afdal_uloom_tilawat/app/route_guard.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const locations = ['/', '/login', '/admin', '/teacher', '/student'];
  AsyncValue<AuthSession?> signedInAs(UserRole role) =>
      AsyncData(AuthSession(uid: 'u', role: role));

  test('unknown session: everything goes to the splash screen', () {
    const unknown = AsyncLoading<AuthSession?>();
    expect(redirectFor(unknown, '/'), isNull);
    for (final location in locations.skip(1)) {
      expect(redirectFor(unknown, location), '/', reason: location);
    }
  });

  test('signed out: everything goes to login', () {
    const signedOut = AsyncData<AuthSession?>(null);
    expect(redirectFor(signedOut, '/login'), isNull);
    for (final location in ['/', '/admin', '/teacher', '/student']) {
      expect(redirectFor(signedOut, location), '/login', reason: location);
    }
  });

  test('session error counts as signed out', () {
    final error = AsyncError<AuthSession?>(
      const AppException(AppErrorCode.network),
      StackTrace.empty,
    );
    expect(redirectFor(error, '/'), '/login');
    expect(redirectFor(error, '/login'), isNull);
  });

  for (final (role, home) in [
    (UserRole.admin, '/admin'),
    (UserRole.teacher, '/teacher'),
    (UserRole.student, '/student'),
  ]) {
    test('${role.name}: lands on $home and cannot open other roles', () {
      final session = signedInAs(role);
      expect(redirectFor(session, home), isNull);
      expect(redirectFor(session, '$home/anything'), isNull);
      for (final location in locations.where((l) => l != home)) {
        expect(redirectFor(session, location), home, reason: location);
      }
    });
  }

  test('a look-alike path is not the home', () {
    expect(redirectFor(signedInAs(UserRole.admin), '/administrator'), '/admin');
  });
}
