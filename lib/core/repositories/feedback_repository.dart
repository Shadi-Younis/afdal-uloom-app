import '../errors/app_exception.dart';
import '../models/feedback_note.dart';

/// Reads and manages teacher notes on a recording
/// (`recordings/{recordingId}/feedback/{id}`). Notes cannot be edited.
///
/// Every method throws [AppException]; streams emit it as an error event.
abstract class FeedbackRepository {
  /// The notes on [recordingId], oldest first.
  ///
  /// Allowed for: whoever can read the recording (its student, its teacher,
  /// admins).
  Stream<List<FeedbackNote>> watch(String recordingId);

  /// Adds [note] and sets the recording's `unreadFeedback` to true, in one
  /// batch: both happen or neither does. `note.id` is ignored (a new id is
  /// generated) and `createdAt` is set to the server time.
  ///
  /// Allowed for: the recording's teacher only, with `note.teacherId` set
  /// to their own uid. The note must be 1..2000 characters, atSecond
  /// 0..36000 and rating 1..5 when given.
  Future<void> add(String recordingId, FeedbackNote note);

  /// Deletes the note [feedbackId].
  ///
  /// Allowed for: the teacher who wrote it, and admins.
  Future<void> delete(String recordingId, String feedbackId);
}
