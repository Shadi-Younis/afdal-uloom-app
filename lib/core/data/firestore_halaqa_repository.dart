import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_paths.dart';
import '../models/halaqa.dart';
import '../repositories/halaqa_repository.dart';
import 'firestore_mapping.dart';

/// [HalaqaRepository] on Cloud Firestore.
class FirestoreHalaqaRepository implements HalaqaRepository {
  FirestoreHalaqaRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _halaqat =>
      _db.collection(FirestorePaths.halaqat);

  @override
  Stream<List<Halaqa>> watchAll() => _watchList(_halaqat.orderBy(Fields.name));

  @override
  Stream<List<Halaqa>> watchForTeacher(String teacherId) => _watchList(
    _halaqat.where(Fields.teacherId, isEqualTo: teacherId).orderBy(Fields.name),
  );

  @override
  Stream<Halaqa?> watch(String halaqaId) => guardStream(
    _db
        .doc(FirestorePaths.halaqa(halaqaId))
        .snapshots()
        .map(
          (doc) =>
              doc.exists ? Halaqa.fromMap(doc.id, readDocument(doc)) : null,
        ),
  );

  @override
  Future<String> create({required String name, required String teacherId}) =>
      guard(() async {
        final doc = await _halaqat.add({
          Fields.name: name,
          Fields.teacherId: teacherId,
        });
        return doc.id;
      });

  @override
  Future<void> rename(String halaqaId, String name) => guard(
    () => _db.doc(FirestorePaths.halaqa(halaqaId)).update({Fields.name: name}),
  );

  @override
  Future<void> setTeacher(String halaqaId, String teacherId) => guard(
    () => _db.doc(FirestorePaths.halaqa(halaqaId)).update({
      Fields.teacherId: teacherId,
    }),
  );

  Stream<List<Halaqa>> _watchList(Query<Map<String, dynamic>> query) =>
      guardStream(
        query.snapshots().map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              Halaqa.fromMap(doc.id, readDocument(doc)),
          ],
        ),
      );
}
