import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_paths.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../repositories/user_repository.dart';
import 'firestore_mapping.dart';

/// [UserRepository] on Cloud Firestore.
class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestorePaths.users);

  @override
  Stream<AppUser?> watchUser(String uid) => guardStream(
    _db
        .doc(FirestorePaths.user(uid))
        .snapshots()
        .map(
          (doc) =>
              doc.exists ? AppUser.fromMap(doc.id, readDocument(doc)) : null,
        ),
  );

  @override
  Stream<List<AppUser>> watchStudentsInHalaqa(String halaqaId) =>
      // The role filter is not redundant: security rules let a teacher read
      // students only, and must be able to prove that from the query.
      _watchList(
        _users
            .where(Fields.halaqaId, isEqualTo: halaqaId)
            .where(Fields.role, isEqualTo: UserRole.student.value)
            .orderBy(Fields.fullName),
      );

  @override
  Stream<List<AppUser>> watchUsersByRole(UserRole role) => _watchList(
    _users.where(Fields.role, isEqualTo: role.value).orderBy(Fields.fullName),
  );

  @override
  Future<void> addFcmToken(String uid, String token) => guard(
    () => _db.doc(FirestorePaths.user(uid)).update({
      Fields.fcmTokens: FieldValue.arrayUnion([token]),
    }),
  );

  @override
  Future<void> removeFcmToken(String uid, String token) => guard(
    () => _db.doc(FirestorePaths.user(uid)).update({
      Fields.fcmTokens: FieldValue.arrayRemove([token]),
    }),
  );

  Stream<List<AppUser>> _watchList(Query<Map<String, dynamic>> query) =>
      guardStream(
        query.snapshots().map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              AppUser.fromMap(doc.id, readDocument(doc)),
          ],
        ),
      );
}
