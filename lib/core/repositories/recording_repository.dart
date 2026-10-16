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
  /// The recordings of [studentId], newest `recordedAt` first; only those
  /// of [type] when given.
  ///
  /// Allowed for: the student themself (every type: his practice is his
  /// own). Admins MUST pass [RecordingType.official]: a practice is
  /// readable only by its student, and rules are not filters (without it
  /// the whole query is denied). A teacher MUST also pass their own uid as
  /// [teacherId]: the query then only asks for recordings of that teacher.
  Stream<List<Recording>> watchForStudent(
    String studentId, {
    String? teacherId,
    RecordingType? type,
  });

  /// The official recordings of [teacherId] that are not reviewed yet,
  /// oldest `createdAt` first (the review queue «بانتظار المراجعة»): their
  /// voice markers wait for the sheikh. Practice recordings are the
  /// student's own and never in it.
  ///
  /// Allowed for: the teacher themself and admins.
  Stream<List<Recording>> watchUnreviewed(String teacherId);

  /// The official recordings of [teacherId] recorded at [since] or later,
  /// newest `recordedAt` first.
  ///
  /// Allowed for: the teacher themself and admins.
  Stream<List<Recording>> watchForTeacherSince(
    String teacherId,
    DateTime since,
  );

  /// The recording [id], then every change; null once it does not exist
  /// (only when the server confirms it, never from the offline cache).
  ///
  /// Allowed for: its student; an official one also its teacher and
  /// admins.
  Stream<Recording?> watch(String id);

  /// The recording [id], or null if it does not exist.
  ///
  /// Allowed for: its student; an official one also its teacher and
  /// admins.
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
  /// Allowed for: the student of the recording (also, for an official
  /// one, its teacher and admins).
  Future<void> markFeedbackRead(String id);

  /// Sets `reviewed` («تمت المراجعة») of an official recording, both
  /// ways.
  ///
  /// Allowed for: the teacher of the recording and admins.
  Future<void> setReviewed(String id, {required bool reviewed});

  /// Sets the surah and ayat of an official recording («تعديل السورة
  /// والآيات»); a null removes that field. Allowed combinations: none, a
  /// surah alone, or a surah with both ayat (1 <= from <= to); anything
  /// else is `AppErrorCode.permissionDenied`. Callers check the ayat
  /// against the surah's length (ayatProblemOf), which rules cannot.
  ///
  /// Allowed for: the teacher of the recording and admins.
  Future<void> setSurahAndAyat(
    String id, {
    required int? surahNumber,
    required int? ayahFrom,
    required int? ayahTo,
  });

  /// Deletes the document only. The audio file and the feedback
  /// subcollection are cleaned up by a Cloud Function (onRecordingDeleted).
  ///
  /// Allowed for: an official recording's teacher and admins («حذف
  /// التسجيل»), a practice's student, at any time («حذف التدريب»).
  Future<void> delete(String id);
}
