import '../errors/app_exception.dart';
import '../models/user_role.dart';

/// Account management through the Cloud Functions in functions/src/accounts.
/// Who may call what is enforced by the functions; see docs/ACCOUNTS.md.
///
/// Every method throws [AppException]: `permissionDenied` (caller not
/// allowed), `invalidData` (input rejected), `notFound`, `usernameTaken`,
/// `studentCodeTaken`, `failedPrecondition` (e.g. the target is not a
/// student) or `network`.
abstract class AccountsService {
  /// Creates an account and returns its uid.
  ///
  /// Admin: any role. Teacher: only students, only into a halaqa they own.
  /// Students need [halaqaId] and [studentCode] (`S` + 3..5 digits); admins
  /// and teachers must have neither. [username]: 3..20 of `a-z 0-9 . _ -`
  /// (trimmed and lower-cased by the server); [password]: 6..64
  /// characters; [fullName]: 2..60 characters.
  Future<String> createUser({
    required String username,
    required String password,
    required String fullName,
    required UserRole role,
    String? halaqaId,
    String? studentCode,
  });

  /// Sets a new password and ends the user's other sessions.
  ///
  /// Admin: any non-admin user, and themselves. Teacher: their own students.
  Future<void> resetPassword({
    required String uid,
    required String newPassword,
  });

  /// Moves a student to [halaqaId], with all their recordings. Returns the
  /// number of recordings updated. Admin only.
  Future<int> moveStudent({
    required String studentId,
    required String halaqaId,
  });

  /// Gives a halaqa to another teacher, with all its recordings. Returns the
  /// number of recordings updated. Admin only.
  Future<int> changeHalaqaTeacher({
    required String halaqaId,
    required String teacherId,
  });

  /// Disables (or enables again) an account; no data is deleted. Admin
  /// only, never on themselves.
  Future<void> setUserDisabled({required String uid, required bool disabled});
}
