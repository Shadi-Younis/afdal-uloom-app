import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/firebase_constants.dart';
import '../firebase_options.dart';

/// `--dart-define=USE_EMULATORS=true`. Only honoured in debug builds, so a
/// release build can never talk to the emulators.
const useEmulators =
    kDebugMode && bool.fromEnvironment(FirebaseConstants.useEmulatorsDefine);

/// A debug build talking to the real project shows a red "PROD" banner.
/// Release builds and emulator runs show nothing.
const showProdBanner = kDebugMode && !useEmulators;

/// `--dart-define=EMULATOR_HOST=<host>`, e.g. the PC's LAN IP for a real phone.
const _emulatorHostOverride = String.fromEnvironment(
  FirebaseConstants.emulatorHostDefine,
);

/// The functions instance for [FirebaseConstants.functionsRegion]. Always call
/// functions through this, never through `FirebaseFunctions.instance`
/// (us-central1).
FirebaseFunctions get regionalFunctions =>
    FirebaseFunctions.instanceFor(region: FirebaseConstants.functionsRegion);

/// Host the emulators are reached on: [override] if given, otherwise
/// `10.0.2.2` on Android (the emulator's alias for the PC) and `localhost`
/// everywhere else, including web.
String resolveEmulatorHost({
  required bool isWeb,
  required TargetPlatform platform,
  String override = '',
}) {
  if (override.isNotEmpty) return override;
  if (!isWeb && platform == TargetPlatform.android) {
    return FirebaseConstants.androidEmulatorHost;
  }
  return FirebaseConstants.defaultEmulatorHost;
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

  const auth = FirebaseConstants.authEmulatorPort;
  const firestore = FirebaseConstants.firestoreEmulatorPort;
  const storage = FirebaseConstants.storageEmulatorPort;
  const functions = FirebaseConstants.functionsEmulatorPort;
  final host = emulatorHost;
  await FirebaseAuth.instance.useAuthEmulator(host, auth);
  FirebaseFirestore.instance.useFirestoreEmulator(host, firestore);
  await FirebaseStorage.instance.useStorageEmulator(host, storage);
  regionalFunctions.useFunctionsEmulator(host, functions);
  debugPrint(
    '[firebase] USING EMULATORS at $host '
    '(auth $auth, firestore $firestore, storage $storage, functions $functions)',
  );
}
