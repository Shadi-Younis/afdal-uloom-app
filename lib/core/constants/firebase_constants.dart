/// Firebase project settings shared by the app and its tests.
abstract final class FirebaseConstants {
  static const projectId = 'afdal-al-uloom';

  /// Region of every Cloud Function. Must match REGION in
  /// functions/src/lib/constants.ts.
  static const functionsRegion = 'me-west1';

  /// Usernames sign in as `<username>@<emailDomain>`. Must match
  /// EMAIL_DOMAIN in functions/src/lib/constants.ts.
  static const emailDomain = 'afdal-uloom.app';

  /// The default Storage bucket, as in firebase_options.dart. Must match
  /// STORAGE_BUCKET in functions/src/lib/constants.ts.
  static const storageBucket = 'afdal-al-uloom.firebasestorage.app';

  /// The `role` custom claim on the ID token; set only by server code.
  static const roleClaim = 'role';

  // Callable function names (functions/src/index.ts).
  static const createUserFunction = 'createUser';
  static const resetPasswordFunction = 'resetPassword';
  static const moveStudentFunction = 'moveStudent';
  static const changeHalaqaTeacherFunction = 'changeHalaqaTeacher';
  static const setUserDisabledFunction = 'setUserDisabled';
  static const deleteHalaqaFunction = 'deleteHalaqa';
  static const deleteUserFunction = 'deleteUser';
  static const updateUserProfileFunction = 'updateUserProfile';

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
