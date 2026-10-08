import '../errors/app_exception.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';

/// Reads user profiles (`users/{uid}`) and manages the caller's push tokens.
///
/// Creating users, changing roles and moving students between halaqat are
/// server-side operations (Cloud Functions), not part of this interface.
///
/// Every method throws [AppException]; streams emit it as an error event.
abstract class UserRepository {
  /// The profile of [uid], or null if it does not exist. Emits again on
  /// every change.
  ///
  /// Allowed for: the user themself, an admin, and the teacher of the
  /// halaqa the user (a student) belongs to. Others get
  /// `AppErrorCode.permissionDenied`.
  Stream<AppUser?> watchUser(String uid);

  /// The students of [halaqaId], sorted by `fullName`.
  ///
  /// Allowed for: an admin and the halaqa's teacher.
  Stream<List<AppUser>> watchStudentsInHalaqa(String halaqaId);

  /// Every user with [role], sorted by `fullName`.
  ///
  /// Allowed for: admins only.
  Stream<List<AppUser>> watchUsersByRole(UserRole role);

  /// Adds a device's push token to `fcmTokens` (no duplicates).
  ///
  /// Allowed for: the user themself ([uid] must be the signed-in user).
  Future<void> addFcmToken(String uid, String token);

  /// Removes a device's push token from `fcmTokens`, e.g. on sign-out.
  /// Does nothing if the token is not there.
  ///
  /// Allowed for: the user themself ([uid] must be the signed-in user).
  Future<void> removeFcmToken(String uid, String token);
}
