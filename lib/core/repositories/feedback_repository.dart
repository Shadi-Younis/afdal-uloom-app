import '../errors/app_exception.dart';
import '../models/feedback_note.dart';

/// Reads and manages the notes on a recording
/// (`recordings/{recordingId}/feedback/{id}`): the teacher's written notes
/// and the sheikh's voice markers, which only the server creates.
///
/// Every method throws [AppException]; streams emit it as an error event.
abstract class FeedbackRepository {
  /// The notes on [recordingId], oldest first.
  ///
  /// Allowed for: whoever can read the recording (its student, its teacher,
  /// admins).
  Stream<List<FeedbackNote>> watch(String recordingId);

  /// Adds the written note [note] (its kind must be text) and sets the
  /// recording's `unreadFeedback` to true, in one batch: both happen or
  /// neither does. `note.id` is ignored (a new id is generated) and
  /// `createdAt` is set to the server time.
  ///
  /// Allowed for: the recording's teacher and admins, with `note.teacherId`
  /// set to their own uid. The note must be 1..2000 characters and
  /// atSecond 0..36000.
  Future<void> add(String recordingId, FeedbackNote note);

  /// Replaces the text of [feedbackId] (a written note or a voice marker),
  /// sets its `updatedAt` to the server time and the recording's
  /// `unreadFeedback` to true, in one batch. A `rating` an old note still
  /// has stays as it is (nobody shows or writes it any more).
  ///
  /// Allowed for: the recording's teacher and admins. [note]: up to 2000
  /// characters, at least one for a written note.
  Future<void> update(
    String recordingId,
    String feedbackId, {
    required String note,
  });

  /// Deletes the note [feedbackId], of either kind.
  ///
  /// Allowed for: the recording's teacher and admins.
  Future<void> delete(String recordingId, String feedbackId);
}
