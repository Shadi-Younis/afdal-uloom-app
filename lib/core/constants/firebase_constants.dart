/// Firebase project settings shared by the app and its tests.
abstract final class FirebaseConstants {
  static const projectId = 'afdal-al-uloom';

  /// Region of every Cloud Function. Must match `setGlobalOptions` in
  /// functions/src/index.ts.
  static const functionsRegion = 'me-west1';

  // Callable function names.
  // TODO: remove once real functions exist; only proves the wiring.
  static const pingFunction = 'ping';

  // Emulator ports, as configured in firebase.json.
  static const authEmulatorPort = 9099;
  static const firestoreEmulatorPort = 8080;
  static const storageEmulatorPort = 9199;
  static const functionsEmulatorPort = 5001;

  /// The Android emulator's alias for the host PC.
  static const androidEmulatorHost = '10.0.2.2';
  static const defaultEmulatorHost = 'localhost';

  // --dart-define keys.
  static const useEmulatorsDefine = 'USE_EMULATORS';
  static const emulatorHostDefine = 'EMULATOR_HOST';
}
