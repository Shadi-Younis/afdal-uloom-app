import '../errors/app_exception.dart';
import '../models/recording.dart';

/// Reads and manages recordings (`recordings/{id}`). The audio file itself
/// lives in Storage and is handled by a separate service.
///
/// Upload flow (teacher studio upload or student practice):
/// 1. `id = newId()`
/// 2. `path = StoragePaths.recording(studentId, id, extension: ...)`
/// 3. `create(recording)` with that id and `storagePath: path`
/// 4. upload the file to `path`
/// 5. if the upload fails, `delete(id)` so no document points at a missing
///    file.
///
/// Every method throws [AppException]; streams emit it as an error event.
abstract class RecordingRepository {
  /// The recordings of [studentId], newest `recordedAt` first.
  ///
  /// Allowed for: the student themself and admins (pass no [teacherId]).
  /// A teacher MUST pass their own uid as [teacherId]: the query then only
  /// asks for recordings of that teacher, which security rules require
  /// (rules are not filters; without it the whole query is denied).
  Stream<List<Recording>> watchForStudent(
    String studentId, {
    String? teacherId,
  });

  /// Practice recordings for [teacherId] that are not reviewed yet, oldest
  /// `createdAt` first (the review queue).
  ///
  /// Allowed for: the teacher themself and admins.
  Stream<List<Recording>> watchPendingPractice(String teacherId);

  /// The recording [id], or null if it does not exist.
  ///
  /// Allowed for: an admin, its teacher and its student.
  Future<Recording?> get(String id);

  /// A fresh document id. Needed before the upload, because the Storage
  /// path contains it. Does not touch the network.
  String newId();

  /// Creates [recording] under `recording.id`, which must come from
  /// [newId]. `createdAt` is set to the server time; the value in
  /// [recording] is ignored.
  ///
  /// Allowed for: a teacher (official, for a student in their halaqa,
  /// `reviewed: true`), a student (practice, for themself,
  /// `reviewed: false`) and admins. Both start with `unreadFeedback: false`.
  /// The halaqaId and teacherId must match the student's halaqa, and the
  /// storagePath must be `recordings/{studentId}/{id}.{ext}`, otherwise
  /// `AppErrorCode.permissionDenied`.
  Future<void> create(Recording recording);

  /// Sets `unreadFeedback` to false after the student opened the notes.
  ///
  /// Allowed for: the student of the recording (also its teacher and
  /// admins).
  Future<void> markFeedbackRead(String id);

  /// Sets `reviewed` to true.
  ///
  /// Allowed for: the teacher of the recording and admins.
  Future<void> markReviewed(String id);

  /// Deletes the document only. The audio file and the feedback
  /// subcollection are cleaned up by a Cloud Function (later task).
  ///
  /// Allowed for: the teacher of the recording and admins.
  Future<void> delete(String id);
}
