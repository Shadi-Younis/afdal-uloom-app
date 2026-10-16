import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_paths.dart';
import '../models/recording.dart';
import '../models/recording_type.dart';
import '../repositories/recording_repository.dart';
import 'firestore_mapping.dart';

/// [RecordingRepository] on Cloud Firestore.
class FirestoreRecordingRepository implements RecordingRepository {
  FirestoreRecordingRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _recordings =>
      _db.collection(FirestorePaths.recordings);

  DocumentReference<Map<String, dynamic>> _doc(String id) =>
      _db.doc(FirestorePaths.recording(id));

  @override
  Stream<List<Recording>> watchForStudent(
    String studentId, {
    String? teacherId,
  }) {
    var query = _recordings.where(Fields.studentId, isEqualTo: studentId);
    if (teacherId != null) {
      query = query.where(Fields.teacherId, isEqualTo: teacherId);
    }
    return _watchList(query.orderBy(Fields.recordedAt, descending: true));
  }

  @override
  Stream<List<Recording>> watchUnreviewed(
    String teacherId, {
    RecordingType? type,
  }) {
    var query = _recordings.where(Fields.teacherId, isEqualTo: teacherId);
    if (type != null) query = query.where(Fields.type, isEqualTo: type.value);
    return _watchList(
      query.where(Fields.reviewed, isEqualTo: false).orderBy(Fields.createdAt),
    );
  }

  @override
  Stream<List<Recording>> watchForTeacherSince(
    String teacherId,
    DateTime since,
  ) => _watchList(
    _recordings
        .where(Fields.teacherId, isEqualTo: teacherId)
        .where(
          Fields.recordedAt,
          isGreaterThanOrEqualTo: Timestamp.fromDate(since),
        )
        .orderBy(Fields.recordedAt, descending: true),
  );

  @override
  Stream<Recording?> watch(String id) =>
      watchDocument(_doc(id), Recording.fromMap);

  @override
  Future<Recording?> get(String id) => guard(() async {
    final doc = await _doc(id).get(estimateServerTimestamps);
    return doc.exists ? Recording.fromMap(doc.id, readDocument(doc)) : null;
  });

  @override
  String newId() => _recordings.doc().id;

  @override
  Future<void> create(Recording recording) => guard(
    () => _doc(recording.id).set({
      ...toFirestore(recording.toMap()),
      Fields.createdAt: FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> markFeedbackRead(String id) =>
      guard(() => _doc(id).update({Fields.unreadFeedback: false}));

  @override
  Future<void> setReviewed(String id, {required bool reviewed}) =>
      guard(() => _doc(id).update({Fields.reviewed: reviewed}));

  @override
  Future<void> setSurahAndAyat(
    String id, {
    required int? surahNumber,
    required int? ayahFrom,
    required int? ayahTo,
  }) => guard(
    () => _doc(id).update({
      // Removed rather than null: a new recording leaves them out too.
      Fields.surahNumber: surahNumber ?? FieldValue.delete(),
      Fields.ayahFrom: ayahFrom ?? FieldValue.delete(),
      Fields.ayahTo: ayahTo ?? FieldValue.delete(),
    }),
  );

  @override
  Future<void> delete(String id) => guard(() => _doc(id).delete());

  Stream<List<Recording>> _watchList(Query<Map<String, dynamic>> query) =>
      guardStream(
        query.snapshots().map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              Recording.fromMap(doc.id, readDocument(doc)),
          ],
        ),
      );
}
