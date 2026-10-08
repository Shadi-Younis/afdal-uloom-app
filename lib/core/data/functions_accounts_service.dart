import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../constants/firebase_constants.dart';
import '../errors/app_exception.dart';
import '../errors/firebase_error_mapper.dart';
import '../models/user_role.dart';
import '../services/accounts_service.dart';

/// Calls the callable [name] with [data] and returns the result's data.
typedef CallFunction = Future<Object?> Function(String name, Object? data);

/// [AccountsService] on the account Cloud Functions.
class FunctionsAccountsService implements AccountsService {
  /// [functions] must be `regionalFunctions` (me-west1).
  FunctionsAccountsService(FirebaseFunctions functions)
    : _call = ((name, data) async =>
          (await functions.httpsCallable(name).call<Object?>(data)).data);

  /// For tests: [call] stands in for the network.
  @visibleForTesting
  FunctionsAccountsService.withCaller(CallFunction call) : _call = call;

  final CallFunction _call;

  @override
  Future<String> createUser({
    required String username,
    required String password,
    required String fullName,
    required UserRole role,
    String? halaqaId,
    String? studentCode,
  }) async {
    final result = await _invoke(FirebaseConstants.createUserFunction, {
      'username': username,
      'password': password,
      'fullName': fullName,
      'role': role.value,
      'halaqaId': ?halaqaId,
      'studentCode': ?studentCode,
    });
    return _read<String>(result, 'uid');
  }

  @override
  Future<void> resetPassword({
    required String uid,
    required String newPassword,
  }) => _invoke(FirebaseConstants.resetPasswordFunction, {
    'uid': uid,
    'newPassword': newPassword,
  });

  @override
  Future<int> moveStudent({
    required String studentId,
    required String halaqaId,
  }) async => _read<int>(
    await _invoke(FirebaseConstants.moveStudentFunction, {
      'studentId': studentId,
      'halaqaId': halaqaId,
    }),
    'recordingsUpdated',
  );

  @override
  Future<int> changeHalaqaTeacher({
    required String halaqaId,
    required String teacherId,
  }) async => _read<int>(
    await _invoke(FirebaseConstants.changeHalaqaTeacherFunction, {
      'halaqaId': halaqaId,
      'teacherId': teacherId,
    }),
    'recordingsUpdated',
  );

  @override
  Future<void> setUserDisabled({required String uid, required bool disabled}) =>
      _invoke(FirebaseConstants.setUserDisabledFunction, {
        'uid': uid,
        'disabled': disabled,
      });

  Future<Object?> _invoke(String name, Map<String, Object?> data) async {
    try {
      return await _call(name, data);
    } on FirebaseFunctionsException catch (error, stackTrace) {
      throw AppException(
        appErrorCodeForFunctions(error.code, error.details),
        cause: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      throw toAppException(error, stackTrace);
    }
  }

  T _read<T>(Object? result, String key) {
    if (result is Map && result[key] is T) return result[key] as T;
    throw AppException(
      AppErrorCode.invalidData,
      cause: FormatException('Expected "$key" in the result', result),
    );
  }
}

/// Maps a Functions error code (and its details) to an [AppErrorCode].
/// `already-exists` carries `{field: 'username' | 'studentCode'}`.
AppErrorCode appErrorCodeForFunctions(String code, Object? details) =>
    switch (code) {
      'already-exists' => switch (details) {
        {'field': 'studentCode'} => AppErrorCode.studentCodeTaken,
        _ => AppErrorCode.usernameTaken,
      },
      'failed-precondition' => AppErrorCode.failedPrecondition,
      'internal' => AppErrorCode.unknown,
      _ => appErrorCodeFor(code),
    };
