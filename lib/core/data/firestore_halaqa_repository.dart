import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_paths.dart';
import '../errors/app_exception.dart';
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
  Stream<Halaqa?> watch(String halaqaId) =>
      watchDocument(_db.doc(FirestorePaths.halaqa(halaqaId)), Halaqa.fromMap);

  // The teacher's name is read just before writing; firestore.rules refuse
  // the write if it changed in between (the admin then tries again).
  @override
  Future<String> create({required String name, required String teacherId}) =>
      guard(() async {
        final teacher = await _db.doc(FirestorePaths.user(teacherId)).get();
        final teacherName = teacher.data()?[Fields.fullName];
        if (teacherName is! String) {
          throw const AppException(AppErrorCode.notFound);
        }
        final doc = await _halaqat.add({
          Fields.name: name,
          Fields.teacherId: teacherId,
          Fields.teacherName: teacherName,
        });
        return doc.id;
      });

  @override
  Future<void> rename(String halaqaId, String name) => guard(
    () => _db.doc(FirestorePaths.halaqa(halaqaId)).update({Fields.name: name}),
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
