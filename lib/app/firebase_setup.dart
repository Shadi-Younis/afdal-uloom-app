import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Region of every Cloud Function. Must match `setGlobalOptions` in
/// functions/src/index.ts.
const kFunctionsRegion = 'me-west1';

/// Emulator ports, as configured in firebase.json.
const kAuthEmulatorPort = 9099;
const kFirestoreEmulatorPort = 8080;
const kStorageEmulatorPort = 9199;
const kFunctionsEmulatorPort = 5001;

/// `--dart-define=USE_EMULATORS=true`. Only honoured in debug builds, so a
/// release build can never talk to the emulators.
const useEmulators = kDebugMode && bool.fromEnvironment('USE_EMULATORS');

/// `--dart-define=EMULATOR_HOST=<host>`, e.g. the PC's LAN IP for a real phone.
const _emulatorHostOverride = String.fromEnvironment('EMULATOR_HOST');

/// The functions instance for [kFunctionsRegion]. Always call functions
/// through this, never through `FirebaseFunctions.instance` (us-central1).
FirebaseFunctions get regionalFunctions =>
    FirebaseFunctions.instanceFor(region: kFunctionsRegion);

/// Host the emulators are reached on: [override] if given, otherwise
/// `10.0.2.2` on Android (the emulator's alias for the PC) and `localhost`
/// everywhere else, including web.
String resolveEmulatorHost({
  required bool isWeb,
  required TargetPlatform platform,
  String override = '',
}) {
  if (override.isNotEmpty) return override;
  if (!isWeb && platform == TargetPlatform.android) return '10.0.2.2';
  return 'localhost';
}

String get emulatorHost => resolveEmulatorHost(
  isWeb: kIsWeb,
  platform: defaultTargetPlatform,
  override: _emulatorHostOverride,
);

/// Initializes Firebase and, if [useEmulators], points every service at the
/// local Emulator Suite. Called once from main(), before runApp.
Future<void> initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!useEmulators) return;

  final host = emulatorHost;
  await FirebaseAuth.instance.useAuthEmulator(host, kAuthEmulatorPort);
  FirebaseFirestore.instance.useFirestoreEmulator(host, kFirestoreEmulatorPort);
  await FirebaseStorage.instance.useStorageEmulator(host, kStorageEmulatorPort);
  regionalFunctions.useFunctionsEmulator(host, kFunctionsEmulatorPort);
  debugPrint(
    '[firebase] USING EMULATORS at $host '
    '(auth $kAuthEmulatorPort, firestore $kFirestoreEmulatorPort, '
    'storage $kStorageEmulatorPort, functions $kFunctionsEmulatorPort)',
  );
}
