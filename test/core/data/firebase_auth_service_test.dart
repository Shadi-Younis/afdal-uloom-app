import 'package:afdal_uloom_tilawat/core/data/firebase_auth_service.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

Matcher throwsAppError(AppErrorCode code) =>
    throwsA(isA<AppException>().having((e) => e.code, 'code', code));

MockFirebaseAuth authWith({Object? role, bool signedIn = false}) =>
    MockFirebaseAuth(
      signedIn: signedIn,
      mockUser: MockUser(
        uid: 'u1',
        email: 'shadi@afdal-uloom.app',
        customClaim: {'role': ?role},
      ),
    );

void main() {
  group('appErrorCodeForAuth', () {
    const expected = {
      'invalid-credential': AppErrorCode.invalidCredentials,
      'wrong-password': AppErrorCode.invalidCredentials,
      'user-not-found': AppErrorCode.invalidCredentials,
      'invalid-email': AppErrorCode.invalidCredentials,
      'user-disabled': AppErrorCode.accountDisabled,
      'too-many-requests': AppErrorCode.tooManyAttempts,
      'network-request-failed': AppErrorCode.network,
      'internal-error': AppErrorCode.unknown,
    };
    for (final MapEntry(key: firebaseCode, value: code) in expected.entries) {
      test('$firebaseCode -> ${code.name}', () {
        expect(appErrorCodeForAuth(firebaseCode), code);
      });
    }
  });

  group('signIn', () {
    test('succeeds for a user with a role claim', () async {
      final auth = authWith(role: 'admin');
      await FirebaseAuthService(auth).signIn('  Shadi ', 'test1234');
      expect(auth.currentUser?.uid, 'u1');
    });

    test('a user without a role is signed out again: noRole', () async {
      final auth = authWith();
      await expectLater(
        FirebaseAuthService(auth).signIn('shadi', 'test1234'),
        throwsAppError(AppErrorCode.noRole),
      );
      expect(auth.currentUser, isNull);
    });

    test('an unknown role counts as no role', () async {
      final auth = authWith(role: 'parent');
      await expectLater(
        FirebaseAuthService(auth).signIn('shadi', 'test1234'),
        throwsAppError(AppErrorCode.noRole),
      );
      expect(auth.currentUser, isNull);
    });

    const errors = {
      'invalid-credential': AppErrorCode.invalidCredentials,
      'wrong-password': AppErrorCode.invalidCredentials,
      'user-not-found': AppErrorCode.invalidCredentials,
      'user-disabled': AppErrorCode.accountDisabled,
      'too-many-requests': AppErrorCode.tooManyAttempts,
      'network-request-failed': AppErrorCode.network,
    };
    for (final MapEntry(key: firebaseCode, value: code) in errors.entries) {
      test('FirebaseAuthException $firebaseCode -> ${code.name}', () async {
        final auth = authWith(role: 'admin');
        whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
            .on(auth)
            .thenThrow(FirebaseAuthException(code: firebaseCode));
        await expectLater(
          FirebaseAuthService(auth).signIn('shadi', 'x'),
          throwsAppError(code),
        );
      });
    }
  });

  group('sessionChanges', () {
    test('emits the session of a signed-in user with a role', () async {
      final auth = authWith(role: 'teacher', signedIn: true);
      expect(
        await FirebaseAuthService(auth).sessionChanges().first,
        const AuthSession(uid: 'u1', role: UserRole.teacher),
      );
    });

    test('emits null when signed out', () async {
      expect(
        await FirebaseAuthService(authWith()).sessionChanges().first,
        isNull,
      );
    });

    test(
      'a signed-in user without a role is signed out and emits null',
      () async {
        final auth = authWith(signedIn: true);
        expect(await FirebaseAuthService(auth).sessionChanges().first, isNull);
        expect(auth.currentUser, isNull);
      },
    );

    test('follows sign-in and sign-out', () async {
      final auth = authWith(role: 'student');
      final service = FirebaseAuthService(auth);
      final sessions = <AuthSession?>[];
      final subscription = service.sessionChanges().listen(sessions.add);

      await service.signIn('s001', 'test1234');
      await service.signOut();
      await pumpEventQueue();
      await subscription.cancel();

      expect(sessions, [
        null,
        const AuthSession(uid: 'u1', role: UserRole.student),
        null,
      ]);
    });
  });
}
