import '../errors/app_exception.dart';
import '../models/recording.dart';
import '../models/recording_type.dart';

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

  /// The recordings of [type] for [teacherId] that are not reviewed yet,
  /// oldest `createdAt` first (the review queue): official ones whose voice
  /// markers the sheikh has not checked, practice ones not listened to.
  ///
  /// Allowed for: the teacher themself and admins.
  Stream<List<Recording>> watchUnreviewed(
    String teacherId,
    RecordingType type,
  );

  /// The recordings of [teacherId] recorded at [since] or later, newest
  /// `recordedAt` first.
  ///
  /// Allowed for: the teacher themself and admins.
  Stream<List<Recording>> watchForTeacherSince(
    String teacherId,
    DateTime since,
  );

  /// The recording [id], then every change; null once it does not exist
  /// (only when the server confirms it, never from the offline cache).
  ///
  /// Allowed for: an admin, its teacher and its student.
  Stream<Recording?> watch(String id);

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
  /// Allowed for: a teacher (official, for a student in their halaqa), a
  /// student (practice, for themself) and admins; both start
  /// `reviewed: false`. Both start with `unreadFeedback: false`.
  /// The halaqaId and teacherId must match the student's halaqa, and the
  /// storagePath must be `recordings/{studentId}/{id}.{ext}`, otherwise
  /// `AppErrorCode.permissionDenied`.
  Future<void> create(Recording recording);

  /// Sets `unreadFeedback` to false after the student opened the notes.
  ///
  /// Allowed for: the student of the recording (also its teacher and
  /// admins).
  Future<void> markFeedbackRead(String id);

  /// Sets `reviewed` («تمت المراجعة»), both ways.
  ///
  /// Allowed for: the teacher of the recording and admins.
  Future<void> setReviewed(String id, {required bool reviewed});

  /// Deletes the document only. The audio file and the feedback
  /// subcollection are cleaned up by a Cloud Function (later task).
  ///
  /// Allowed for: the teacher of the recording and admins.
  Future<void> delete(String id);
}
