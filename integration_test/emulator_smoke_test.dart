// Smoke test for the Firebase wiring. Runs ONLY against the Emulator Suite:
//
//   firebase emulators:start
//   flutter test integration_test/emulator_smoke_test.dart -d <device> \
//     --dart-define=USE_EMULATORS=true [--dart-define=EMULATOR_HOST=<LAN IP>]
//
// Proves that Auth, Firestore, Storage and Functions (me-west1) all reach the
// emulators. Rules are deny-all for now, so Firestore and Storage must refuse.
import 'dart:convert';

import 'package:afdal_uloom_tilawat/app/firebase_setup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

const _projectId = 'afdal-al-uloom';
const _timeout = Duration(seconds: 20);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String uid;

  setUpAll(() async {
    // Never let this test touch the real project.
    if (!useEmulators) {
      fail('Run with --dart-define=USE_EMULATORS=true (debug build).');
    }
    await initFirebase();
  });

  test('create a user the way the server will (admin API)', () async {
    final email = 'smoke-${DateTime.now().millisecondsSinceEpoch}@test.local';
    // Client sign-up is disabled in production, so accounts are created with
    // admin rights. "Bearer owner" is the Auth emulator's admin credential.
    final response = await http.post(
      Uri.http(
        '$emulatorHost:$kAuthEmulatorPort',
        '/identitytoolkit.googleapis.com/v1/projects/$_projectId/accounts',
      ),
      headers: {
        'Authorization': 'Bearer owner',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': 'smoke-pass-123'}),
    );
    expect(response.statusCode, 200, reason: response.body);
    final created = jsonDecode(response.body)['localId'] as String;
    debugPrint('[smoke] created user $email uid=$created');

    final credential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: 'smoke-pass-123')
        .timeout(_timeout);
    uid = credential.user!.uid;
    expect(uid, created);
    debugPrint('[smoke] signed in uid=$uid');
  });

  test('Firestore refuses writes and reads (deny-all rules)', () async {
    final doc = FirebaseFirestore.instance.doc('smoke/$uid');

    final write = await _firebaseError(() => doc.set({'at': 'smoke'}));
    expect(write.code, 'permission-denied');
    debugPrint('[smoke] firestore write -> ${write.code}');

    final read = await _firebaseError(
      () => doc.get(const GetOptions(source: Source.server)),
    );
    expect(read.code, 'permission-denied');
    debugPrint('[smoke] firestore read -> ${read.code}');
  });

  test('Storage refuses uploads (deny-all rules)', () async {
    final upload = await _firebaseError(
      () => FirebaseStorage.instance.ref('smoke/$uid.txt').putString('smoke'),
    );
    expect(upload.code, 'unauthorized');
    debugPrint('[smoke] storage upload -> ${upload.code}');
  });

  test('ping in me-west1 answers with the signed-in uid', () async {
    final result = await regionalFunctions
        .httpsCallable('ping')
        .call<Map<String, dynamic>>()
        .timeout(_timeout);
    expect(result.data, {'ok': true, 'uid': uid});
    debugPrint('[smoke] ping -> ${result.data}');
  });
}

Future<FirebaseException> _firebaseError(Future<Object?> Function() run) async {
  try {
    await run().timeout(_timeout);
  } on FirebaseException catch (e) {
    return e;
  }
  throw TestFailure('expected a FirebaseException, but the call succeeded');
}
