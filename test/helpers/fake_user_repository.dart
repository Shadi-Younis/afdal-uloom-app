import 'dart:async';

import 'package:afdal_uloom_tilawat/core/models/app_user.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/repositories/user_repository.dart';

/// A [UserRepository] over an in-memory map of users. Streams emit again
/// after [put], like Firestore snapshots. [watchError], when set, is
/// emitted instead of any data.
class FakeUserRepository implements UserRepository {
  FakeUserRepository([Map<String, AppUser>? users]) : users = users ?? {};

  final Map<String, AppUser> users;
  Object? watchError;

  final _changed = StreamController<void>.broadcast();

  /// Adds or replaces [user]; every open stream emits again.
  void put(AppUser user) {
    users[user.id] = user;
    _changed.add(null);
  }

  /// Removes the user [uid]; every open stream emits again.
  void remove(String uid) {
    users.remove(uid);
    _changed.add(null);
  }

  @override
  Stream<AppUser?> watchUser(String uid) => _live(() => users[uid]);

  @override
  Stream<List<AppUser>> watchStudentsInHalaqa(String halaqaId) => _live(
    () => _sorted((u) => u.role == UserRole.student && u.halaqaId == halaqaId),
  );

  @override
  Stream<List<AppUser>> watchUsersByRole(UserRole role) =>
      _live(() => _sorted((u) => u.role == role));

  @override
  Future<void> addFcmToken(String uid, String token) =>
      throw UnimplementedError();

  @override
  Future<void> removeFcmToken(String uid, String token) =>
      throw UnimplementedError();

  List<AppUser> _sorted(bool Function(AppUser) test) =>
      users.values.where(test).toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));

  Stream<T> _live<T>(T Function() read) async* {
    if (watchError case final error?) throw error;
    yield read();
    yield* _changed.stream.map((_) => read());
  }
}

/// A user as the seed creates them.
AppUser seedUser(String uid, String fullName, UserRole role) => AppUser(
  id: uid,
  username: uid,
  fullName: fullName,
  role: role,
  createdAt: DateTime(2026, 9),
);

/// A student as the seed creates them: username [uid], code in upper case.
AppUser seedStudent(
  String uid,
  String fullName,
  String halaqaId, {
  bool disabled = false,
}) => AppUser(
  id: uid,
  username: uid,
  fullName: fullName,
  role: UserRole.student,
  studentCode: uid.toUpperCase(),
  halaqaId: halaqaId,
  createdAt: DateTime(2026, 9),
  disabled: disabled,
);
