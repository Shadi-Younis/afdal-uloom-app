// Smoke test for the Firebase wiring. Runs ONLY against the Emulator Suite:
//
//   powershell -ExecutionPolicy Bypass -File tool/emulators.ps1
//   flutter test integration_test/emulator_smoke_test.dart -d <device> \
//     --dart-define=USE_EMULATORS=true [--dart-define=EMULATOR_HOST=<LAN IP>]
//
// Proves that sign-in through AuthService (with the role claim), Firestore,
// Storage and the account Functions (me-west1) all reach the emulators.
import 'dart:convert';

import 'package:afdal_uloom_tilawat/app/firebase_setup.dart';
import 'package:afdal_uloom_tilawat/core/constants/app_durations.dart';
import 'package:afdal_uloom_tilawat/core/constants/firebase_constants.dart';
import 'package:afdal_uloom_tilawat/core/data/firebase_auth_service.dart';
import 'package:afdal_uloom_tilawat/core/data/functions_accounts_service.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

const _timeout = AppDurations.firebaseCallTimeout;
const _password = 'smoke-pass-123';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseAuthService authService;
  late String uid;

  setUpAll(() async {
    // Never let this test touch the real project.
    if (!useEmulators) {
      fail('Run with --dart-define=USE_EMULATORS=true (debug build).');
    }
    await initFirebase();
    authService = FirebaseAuthService(FirebaseAuth.instance);
  });

  test('a user without a role claim is refused: noRole', () async {
    final username = 'smoke-norole-${DateTime.now().millisecondsSinceEpoch}';
    await _createAccount(username, role: null);
    await expectLater(
      authService.signIn(username, _password).timeout(_timeout),
      throwsA(
        isA<AppException>().having((e) => e.code, 'code', AppErrorCode.noRole),
      ),
    );
    expect(FirebaseAuth.instance.currentUser, isNull);
  });

  test('sign in through AuthService; the session carries the role', () async {
    final username = 'smoke-${DateTime.now().millisecondsSinceEpoch}';
    uid = await _createAccount(username, role: 'student');

    await authService.signIn(username, _password).timeout(_timeout);
    final session = await authService
        .sessionChanges()
        .firstWhere((s) => s != null)
        .timeout(_timeout);
    expect(session, AuthSession(uid: uid, role: UserRole.student));
    debugPrint('[smoke] signed in $session');
  });

  test('Firestore refuses a collection outside the data model', () async {
    final doc = FirebaseFirestore.instance.doc('smoke/$uid');
    final write = await _firebaseError(() => doc.set({'at': 'smoke'}));
    expect(write.code, 'permission-denied');
    debugPrint('[smoke] firestore write -> ${write.code}');
  });

  test('Storage refuses uploads (deny-all rules)', () async {
    final upload = await _firebaseError(
      () => FirebaseStorage.instance.ref('smoke/$uid.txt').putString('smoke'),
    );
    expect(upload.code, 'unauthorized');
    debugPrint('[smoke] storage upload -> ${upload.code}');
  });

  test(
    'createUser in me-west1 answers a student with permissionDenied',
    () async {
      final accounts = FunctionsAccountsService(regionalFunctions);
      await expectLater(
        accounts
            .createUser(
              username: 'not-allowed',
              password: _password,
              fullName: 'طالب',
              role: UserRole.student,
              halaqaId: 'h',
              studentCode: 'S999',
            )
            .timeout(_timeout),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.permissionDenied,
          ),
        ),
      );
      debugPrint('[smoke] createUser as student -> permissionDenied');
    },
  );

  test('sign out ends the session', () async {
    await authService.signOut();
    expect(await authService.sessionChanges().first, isNull);
  });
}

/// Creates an account with the Auth emulator's admin API ("Bearer owner"),
/// the way the createUser function would, and returns its uid.
Future<String> _createAccount(String username, {required String? role}) async {
  Uri endpoint(String path) => Uri.http(
    '$emulatorHost:${FirebaseConstants.authEmulatorPort}',
    '/identitytoolkit.googleapis.com/v1/projects/'
        '${FirebaseConstants.projectId}/$path',
  );
  const headers = {
    'Authorization': 'Bearer owner',
    'Content-Type': 'application/json',
  };

  final created = await http.post(
    endpoint('accounts'),
    headers: headers,
    body: jsonEncode({
      'email': '$username@${FirebaseConstants.emailDomain}',
      'password': _password,
    }),
  );
  expect(created.statusCode, 200, reason: created.body);
  final uid = jsonDecode(created.body)['localId'] as String;

  if (role != null) {
    final claims = await http.post(
      endpoint('accounts:update'),
      headers: headers,
      body: jsonEncode({
        'localId': uid,
        'customAttributes': jsonEncode({FirebaseConstants.roleClaim: role}),
      }),
    );
    expect(claims.statusCode, 200, reason: claims.body);
  }
  debugPrint('[smoke] created $username uid=$uid role=$role');
  return uid;
}

Future<FirebaseException> _firebaseError(Future<Object?> Function() run) async {
  try {
    await run().timeout(_timeout);
  } on FirebaseException catch (e) {
    return e;
  }
  throw TestFailure('expected a FirebaseException, but the call succeeded');
}
