import '../errors/app_exception.dart';
import '../models/user_role.dart';

/// Account management through the Cloud Functions in functions/src/accounts.
/// Who may call what is enforced by the functions; see docs/ACCOUNTS.md.
///
/// Every method throws [AppException]: `permissionDenied` (caller not
/// allowed), `invalidData` (input rejected), `notFound`, `usernameTaken`,
/// `studentCodeTaken`, `failedPrecondition` (e.g. the target is not a
/// student), one of the refusals documented on the method, or `network`.
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
  /// only, never on themselves. Throws `lastAdmin` for the only active
  /// admin.
  Future<void> setUserDisabled({required String uid, required bool disabled});

  /// Deletes an empty halaqa. Admin only. Throws `halaqaHasStudents` while
  /// a student (even a disabled one) belongs to it, `halaqaHasRecordings`
  /// while a recording still points to it.
  Future<void> deleteHalaqa(String halaqaId);

  /// Deletes a teacher or a student for good and returns how many
  /// recordings were deleted with it (always 0 for a teacher). A student
  /// loses every recording, its audio and its feedback. Admin only; admin
  /// accounts can never be deleted (`permissionDenied`). Throws
  /// `teacherOwnsHalaqat` while the teacher teaches a halaqa.
  Future<int> deleteUser(String uid);

  /// Changes the given fields of [uid]'s profile; null fields stay as they
  /// are, and at least one must be given. Admin: any user, themselves
  /// included. Teacher: only the [fullName] of their own students.
  /// [username] also changes the sign-in name (`usernameTaken` if used);
  /// [studentCode] is for students only (`studentCodeTaken` if used).
  Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? username,
    String? studentCode,
  });
}
