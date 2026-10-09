import 'dart:async';

import 'package:afdal_uloom_tilawat/core/models/app_user.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/services/accounts_service.dart';

import 'fake_halaqa_repository.dart';
import 'fake_user_repository.dart';

/// An [AccountsService] that records its calls and, when given the fake
/// repositories, applies their effects to them, as the functions do to
/// Firestore (so screens update through their streams).
///
/// - [error]: what every call throws.
/// - [gate]: when set, every call waits for it (to test loading states).
class FakeAccountsService implements AccountsService {
  FakeAccountsService({this.users, this.halaqat});

  final FakeUserRepository? users;
  final FakeHalaqaRepository? halaqat;
  Object? error;
  Completer<void>? gate;

  final createUserCalls = <Map<String, Object?>>[];
  final resetPasswordCalls = <(String uid, String password)>[];
  final moveStudentCalls = <(String studentId, String halaqaId)>[];
  final changeTeacherCalls = <(String halaqaId, String teacherId)>[];
  final setDisabledCalls = <(String uid, bool disabled)>[];
  final deleteHalaqaCalls = <String>[];
  final deleteUserCalls = <String>[];
  final updateProfileCalls = <Map<String, Object?>>[];

  /// What deleteUser returns as the number of deleted recordings.
  int recordingsDeleted = 0;

  @override
  Future<String> createUser({
    required String username,
    required String password,
    required String fullName,
    required UserRole role,
    String? halaqaId,
    String? studentCode,
  }) async {
    createUserCalls.add({
      'username': username,
      'password': password,
      'fullName': fullName,
      'role': role,
      'halaqaId': halaqaId,
      'studentCode': studentCode,
    });
    await _call();
    final uid = 'uid-$username';
    users?.put(
      AppUser(
        id: uid,
        username: username,
        fullName: fullName,
        role: role,
        studentCode: studentCode,
        halaqaId: halaqaId,
        createdAt: DateTime(2026, 10, 9),
      ),
    );
    return uid;
  }

  @override
  Future<void> resetPassword({
    required String uid,
    required String newPassword,
  }) async {
    resetPasswordCalls.add((uid, newPassword));
    await _call();
  }

  @override
  Future<int> moveStudent({
    required String studentId,
    required String halaqaId,
  }) async {
    moveStudentCalls.add((studentId, halaqaId));
    await _call();
    final student = users?.users[studentId];
    if (student != null) users!.put(student.copyWith(halaqaId: halaqaId));
    return 0;
  }

  @override
  Future<int> changeHalaqaTeacher({
    required String halaqaId,
    required String teacherId,
  }) async {
    changeTeacherCalls.add((halaqaId, teacherId));
    await _call();
    final halaqa = halaqat?.halaqat[halaqaId];
    if (halaqa != null) halaqat!.put(halaqa.copyWith(teacherId: teacherId));
    return 0;
  }

  @override
  Future<void> setUserDisabled({
    required String uid,
    required bool disabled,
  }) async {
    setDisabledCalls.add((uid, disabled));
    await _call();
    final user = users?.users[uid];
    if (user != null) users!.put(user.copyWith(disabled: disabled));
  }

  @override
  Future<void> deleteHalaqa(String halaqaId) async {
    deleteHalaqaCalls.add(halaqaId);
    await _call();
    halaqat?.remove(halaqaId);
  }

  @override
  Future<int> deleteUser(String uid) async {
    deleteUserCalls.add(uid);
    await _call();
    users?.remove(uid);
    return recordingsDeleted;
  }

  @override
  Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? username,
    String? studentCode,
  }) async {
    updateProfileCalls.add({
      'uid': uid,
      'fullName': ?fullName,
      'username': ?username,
      'studentCode': ?studentCode,
    });
    await _call();
    final user = users?.users[uid];
    if (user != null) {
      users!.put(
        user.copyWith(
          fullName: fullName,
          username: username,
          studentCode: studentCode,
        ),
      );
    }
  }

  Future<void> _call() async {
    await gate?.future;
    if (error case final error?) throw error;
  }
}
