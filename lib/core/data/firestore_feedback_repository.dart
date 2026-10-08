import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_paths.dart';
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
  Future<void> add(String recordingId, FeedbackNote note) => guard(() {
    // One batch, so the student is never told about a note that failed to
    // save, and never misses one that was saved.
    final batch = _db.batch()
      ..set(_notes(recordingId).doc(), {
        ...toFirestore(note.toMap()),
        Fields.createdAt: FieldValue.serverTimestamp(),
      })
      ..update(_db.doc(FirestorePaths.recording(recordingId)), {
        Fields.unreadFeedback: true,
      });
    return batch.commit();
  });

  @override
  Future<void> delete(String recordingId, String feedbackId) =>
      guard(() => _notes(recordingId).doc(feedbackId).delete());
}
