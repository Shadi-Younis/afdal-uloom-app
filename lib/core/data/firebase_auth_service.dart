import 'package:firebase_auth/firebase_auth.dart';

import '../constants/firebase_constants.dart';
import '../errors/app_exception.dart';
import '../errors/firebase_error_mapper.dart';
import '../models/auth_session.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

/// [AuthService] on Firebase Authentication.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<AuthSession?> sessionChanges() =>
      // idTokenChanges, not authStateChanges: it fires again when a token is
      // refreshed, so a session whose role could not be read while offline
      // comes back once the network does.
      _auth.idTokenChanges().asyncMap((user) async {
        if (user == null) return null;
        try {
          final role = await _roleOf(user, forceRefresh: false);
          if (role == null) {
            await _auth.signOut();
            return null;
          }
          return AuthSession(uid: user.uid, role: role);
        } catch (error, stackTrace) {
          throw toAppException(error, stackTrace);
        }
      });

  @override
  Future<void> signIn(String username, String password) async {
    final email =
        '${username.trim().toLowerCase()}'
        '@${FirebaseConstants.emailDomain}';
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Forced once: a cached token may predate the role claim.
      final role = await _roleOf(credential.user!, forceRefresh: true);
      if (role == null) {
        await _auth.signOut();
        throw const AppException(AppErrorCode.noRole);
      }
    } on FirebaseAuthException catch (error, stackTrace) {
      throw AppException(
        appErrorCodeForAuth(error.code),
        cause: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      throw toAppException(error, stackTrace);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (error, stackTrace) {
      throw toAppException(error, stackTrace);
    }
  }

  /// The role claim of [user], or null when it is missing or unknown.
  Future<UserRole?> _roleOf(User user, {required bool forceRefresh}) async {
    final token = await user.getIdTokenResult(forceRefresh);
    final claim = token.claims?[FirebaseConstants.roleClaim];
    if (claim is! String) return null;
    try {
      return UserRole.fromValue(claim);
    } on FormatException {
      return null;
    }
  }
}

/// Maps a [FirebaseAuthException] code from signing in to an [AppErrorCode].
AppErrorCode appErrorCodeForAuth(String code) => switch (code) {
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' ||
  // A username with characters an email cannot have: it cannot exist.
  'invalid-email' => AppErrorCode.invalidCredentials,
  'user-disabled' => AppErrorCode.accountDisabled,
  'too-many-requests' => AppErrorCode.tooManyAttempts,
  'network-request-failed' => AppErrorCode.network,
  _ => appErrorCodeFor(code),
};
