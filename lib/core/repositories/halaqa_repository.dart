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

  /// The halaqa [halaqaId], or null if it does not exist.
  ///
  /// Allowed for: an admin, its teacher, and its students.
  Stream<Halaqa?> watch(String halaqaId);

  /// Creates a halaqa and returns its new id.
  ///
  /// Allowed for: admins only. [name] must be 1..60 characters and
  /// [teacherId] an existing user whose role is teacher, otherwise
  /// `AppErrorCode.permissionDenied` (security rules).
  Future<String> create({required String name, required String teacherId});

  /// Renames [halaqaId]. Same limits on [name] as [create].
  ///
  /// Allowed for: admins only.
  Future<void> rename(String halaqaId, String name);

  /// Gives [halaqaId] to another teacher. Existing recordings keep the
  /// teacherId they were created with.
  ///
  /// Allowed for: admins only. [teacherId] must be a teacher.
  Future<void> setTeacher(String halaqaId, String teacherId);
}
