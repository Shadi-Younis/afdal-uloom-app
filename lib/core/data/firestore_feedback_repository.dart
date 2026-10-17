import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_paths.dart';
import '../models/feedback_kind.dart';
import '../models/feedback_note.dart';
import '../repositories/feedback_repository.dart';
import 'firestore_mapping.dart';

/// [FeedbackRepository] on Cloud Firestore.
class FirestoreFeedbackRepository implements FeedbackRepository {
  FirestoreFeedbackRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _notes(String recordingId) =>
      _db.collection(FirestorePaths.recordingFeedback(recordingId));

  @override
  Stream<List<FeedbackNote>> watch(String recordingId) => guardStream(
    _notes(recordingId)
        .orderBy(Fields.createdAt)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              FeedbackNote.fromMap(doc.id, readDocument(doc)),
          ],
        ),
  );

  @override
  Future<void> add(String recordingId, FeedbackNote note) {
    if (note.kind != FeedbackKind.text) {
      // Voice markers come from the server only (firestore.rules).
      throw ArgumentError.value(note.kind, 'note.kind', 'must be text');
    }
    return guard(() {
      // One batch, so the student is never told about a note that failed
      // to save, and never misses one that was saved. Only the fields a
      // client may create (firestore.rules).
      final batch = _db.batch()
        ..set(_notes(recordingId).doc(), {
          Fields.teacherId: note.teacherId,
          Fields.note: note.note,
          Fields.kind: FeedbackKind.text.value,
          Fields.atSecond: note.atSecond,
          Fields.createdAt: FieldValue.serverTimestamp(),
        });
      _markUnread(batch, recordingId);
      return batch.commit();
    });
  }

  @override
  Future<void> update(
    String recordingId,
    String feedbackId, {
    required String note,
  }) => guard(() {
    final batch = _db.batch()
      ..update(_notes(recordingId).doc(feedbackId), {
        Fields.note: note,
        Fields.updatedAt: FieldValue.serverTimestamp(),
      });
    _markUnread(batch, recordingId);
    return batch.commit();
  });

  void _markUnread(WriteBatch batch, String recordingId) => batch.update(
    _db.doc(FirestorePaths.recording(recordingId)),
    {Fields.unreadFeedback: true},
  );

  @override
  Future<void> delete(String recordingId, String feedbackId) =>
      guard(() => _notes(recordingId).doc(feedbackId).delete());
}
