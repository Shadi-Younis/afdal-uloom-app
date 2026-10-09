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

/// [uid]: mock_exceptions matches users by equality (their uid), so a test
/// that makes a user's method throw needs a uid of its own.
MockFirebaseAuth authWith({
  Object? role,
  bool signedIn = false,
  String uid = 'u1',
}) => MockFirebaseAuth(
  signedIn: signedIn,
  mockUser: MockUser(
    uid: uid,
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

  group('changePassword', () {
    test(
      're-authenticates, sets the new password and stays signed in',
      () async {
        final auth = authWith(role: 'student', signedIn: true);

        await FirebaseAuthService(
          auth,
        ).changePassword(currentPassword: 'old-pass', newPassword: 'new-pass');

        expect(auth.currentUser?.uid, 'u1');
      },
    );

    test('signed out: permissionDenied', () async {
      await expectLater(
        FirebaseAuthService(authWith())
            .changePassword(currentPassword: 'a', newPassword: 'b'),
        throwsAppError(AppErrorCode.permissionDenied),
      );
    });

    const reauthErrors = {
      'invalid-credential': AppErrorCode.wrongPassword,
      'wrong-password': AppErrorCode.wrongPassword,
      'too-many-requests': AppErrorCode.tooManyAttempts,
      'network-request-failed': AppErrorCode.network,
    };
    for (final MapEntry(key: firebaseCode, value: code)
        in reauthErrors.entries) {
      test('re-authentication $firebaseCode -> ${code.name}', () async {
        final auth = authWith(
          role: 'admin',
          signedIn: true,
          uid: 'reauth-$firebaseCode',
        );
        whenCalling(Invocation.method(#reauthenticateWithCredential, null))
            .on(auth.currentUser!)
            .thenThrow(FirebaseAuthException(code: firebaseCode));
        await expectLater(
          FirebaseAuthService(auth)
              .changePassword(currentPassword: 'x', newPassword: 'new-pass'),
          throwsAppError(code),
        );
      });
    }

    test('update weak-password -> weakPassword', () async {
      final auth = authWith(role: 'admin', signedIn: true, uid: 'weak');
      whenCalling(Invocation.method(#updatePassword, null))
          .on(auth.currentUser!)
          .thenThrow(FirebaseAuthException(code: 'weak-password'));
      await expectLater(
        FirebaseAuthService(auth)
            .changePassword(currentPassword: 'old-pass', newPassword: '123'),
        throwsAppError(AppErrorCode.weakPassword),
      );
    });
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
