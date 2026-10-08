import 'package:afdal_uloom_tilawat/core/models/app_user.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/repositories/user_repository.dart';

/// A [UserRepository] over a fixed map of users. [watchError], when set,
/// is emitted instead of the user.
class FakeUserRepository implements UserRepository {
  FakeUserRepository([Map<String, AppUser>? users]) : users = users ?? {};

  final Map<String, AppUser> users;
  Object? watchError;

  @override
  Stream<AppUser?> watchUser(String uid) =>
      watchError != null ? Stream.error(watchError!) : Stream.value(users[uid]);

  @override
  Stream<List<AppUser>> watchStudentsInHalaqa(String halaqaId) =>
      throw UnimplementedError();

  @override
  Stream<List<AppUser>> watchUsersByRole(UserRole role) =>
      throw UnimplementedError();

  @override
  Future<void> addFcmToken(String uid, String token) =>
      throw UnimplementedError();

  @override
  Future<void> removeFcmToken(String uid, String token) =>
      throw UnimplementedError();
}

/// A user as the seed creates them.
AppUser seedUser(String uid, String fullName, UserRole role) => AppUser(
  id: uid,
  username: uid,
  fullName: fullName,
  role: role,
  createdAt: DateTime(2026, 9),
);
