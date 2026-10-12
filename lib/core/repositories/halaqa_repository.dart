import '../errors/app_exception.dart';
import '../models/halaqa.dart';

/// Reads and manages halaqat (`halaqat/{id}`).
///
/// Every method throws [AppException]; streams emit it as an error event.
abstract class HalaqaRepository {
  /// Every halaqa, sorted by `name`.
  ///
  /// Allowed for: admins only.
  Stream<List<Halaqa>> watchAll();

  /// The halaqat taught by [teacherId], sorted by `name`.
  ///
  /// Allowed for: an admin, and the teacher themself.
  Stream<List<Halaqa>> watchForTeacher(String teacherId);

  /// The halaqa [halaqaId], or null if it does not exist (only when the
  /// server confirms it, never from the offline cache).
  ///
  /// Allowed for: an admin, its teacher, and its students.
  Stream<Halaqa?> watch(String halaqaId);

  /// Creates a halaqa and returns its new id. The teacher's current
  /// `fullName` is copied into it as `teacherName`.
  ///
  /// Allowed for: admins only. [name] must be 1..60 characters and
  /// [teacherId] an existing user whose role is teacher, otherwise
  /// `AppErrorCode.permissionDenied` (security rules), or
  /// `AppErrorCode.notFound` when [teacherId] has no profile.
  Future<String> create({required String name, required String teacherId});

  /// Renames [halaqaId]. Same limits on [name] as [create].
  ///
  /// Allowed for: admins only. To give a halaqa another teacher use
  /// AccountsService.changeHalaqaTeacher: it also updates the teacherId
  /// copied into the halaqa's recordings, so security rules deny it here.
  Future<void> rename(String halaqaId, String name);
}
