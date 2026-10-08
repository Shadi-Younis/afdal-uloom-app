import '../errors/app_exception.dart';
import '../models/auth_session.dart';

/// Signing in and out with username + password. Accounts are created only
/// by Cloud Functions (see AccountsService); there is no sign-up.
abstract class AuthService {
  /// The current session, then every change: a session after sign-in, null
  /// after sign-out. A signed-in user without a valid role claim is signed
  /// out and reported as null. Emits [AppException] as an error event when
  /// the role cannot be read (e.g. offline with an expired token).
  Stream<AuthSession?> sessionChanges();

  /// Signs in `<username>@afdal-uloom.app`. [username] is trimmed and
  /// lower-cased first.
  ///
  /// Throws [AppException] with `invalidCredentials`, `accountDisabled`,
  /// `tooManyAttempts`, `network`, or `noRole` (signed in, but the account
  /// has no valid role claim; it is signed out again).
  Future<void> signIn(String username, String password);

  /// Signs out. Never throws for a user who is already signed out.
  Future<void> signOut();
}
