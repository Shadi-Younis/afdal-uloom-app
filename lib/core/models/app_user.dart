import 'package:flutter/foundation.dart' show listEquals;

import '../constants/firestore_paths.dart';
import '../utils/map_reader.dart';
import 'user_role.dart';

/// A user profile (`users/{uid}`). Accounts and roles are created by
/// server code only; the client may change nothing but [fcmTokens].
class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.studentCode,
    this.halaqaId,
    this.fcmTokens = const [],
    required this.createdAt,
  });

  /// Throws [FormatException] for a missing field, a wrong type or an
  /// unknown role.
  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
    id: id,
    username: readRequired<String>(map, Fields.username),
    fullName: readRequired<String>(map, Fields.fullName),
    role: UserRole.fromValue(readRequired<String>(map, Fields.role)),
    studentCode: readOptional<String>(map, Fields.studentCode),
    halaqaId: readOptional<String>(map, Fields.halaqaId),
    fcmTokens: readStringList(map, Fields.fcmTokens),
    createdAt: readRequired<DateTime>(map, Fields.createdAt),
  );

  /// The Firebase Auth uid; not stored in the document.
  final String id;

  /// Login name, e.g. `s023`.
  final String username;
  final String fullName;
  final UserRole role;

  /// Students only, e.g. `S023`.
  final String? studentCode;

  /// Students only.
  final String? halaqaId;

  /// Push notification tokens of the user's devices.
  final List<String> fcmTokens;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    Fields.username: username,
    Fields.fullName: fullName,
    Fields.role: role.value,
    Fields.studentCode: studentCode,
    Fields.halaqaId: halaqaId,
    Fields.fcmTokens: fcmTokens,
    Fields.createdAt: createdAt,
  };

  /// Nullable fields cannot be cleared to null through copyWith.
  AppUser copyWith({
    String? id,
    String? username,
    String? fullName,
    UserRole? role,
    String? studentCode,
    String? halaqaId,
    List<String>? fcmTokens,
    DateTime? createdAt,
  }) => AppUser(
    id: id ?? this.id,
    username: username ?? this.username,
    fullName: fullName ?? this.fullName,
    role: role ?? this.role,
    studentCode: studentCode ?? this.studentCode,
    halaqaId: halaqaId ?? this.halaqaId,
    fcmTokens: fcmTokens ?? this.fcmTokens,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.username == username &&
      other.fullName == fullName &&
      other.role == role &&
      other.studentCode == studentCode &&
      other.halaqaId == halaqaId &&
      listEquals(other.fcmTokens, fcmTokens) &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    username,
    fullName,
    role,
    studentCode,
    halaqaId,
    Object.hashAll(fcmTokens),
    createdAt,
  );

  @override
  String toString() =>
      'AppUser(id: $id, username: $username, fullName: $fullName, '
      'role: ${role.value}, studentCode: $studentCode, halaqaId: $halaqaId, '
      'fcmTokens: ${fcmTokens.length}, createdAt: $createdAt)';
}
