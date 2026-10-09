import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/errors/firebase_error_mapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appErrorCodeFor', () {
    const expected = {
      'permission-denied': AppErrorCode.permissionDenied,
      'unauthenticated': AppErrorCode.permissionDenied,
      'unauthorized': AppErrorCode.permissionDenied,
      'not-found': AppErrorCode.notFound,
      'object-not-found': AppErrorCode.notFound,
      'canceled': AppErrorCode.uploadCancelled,
      'unavailable': AppErrorCode.network,
      'deadline-exceeded': AppErrorCode.network,
      'network-request-failed': AppErrorCode.network,
      'retry-limit-exceeded': AppErrorCode.network,
      'invalid-argument': AppErrorCode.invalidData,
      'out-of-range': AppErrorCode.invalidData,
      'data-loss': AppErrorCode.invalidData,
      'failed-precondition': AppErrorCode.unknown,
      'something-new': AppErrorCode.unknown,
    };
    for (final MapEntry(key: firebaseCode, value: code) in expected.entries) {
      test('$firebaseCode -> ${code.name}', () {
        expect(appErrorCodeFor(firebaseCode), code);
      });
    }
  });

  group('toAppException', () {
    test('FirebaseException keeps the original error as cause', () {
      final error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      final trace = StackTrace.current;
      final result = toAppException(error, trace);
      expect(result.code, AppErrorCode.permissionDenied);
      expect(result.cause, same(error));
      expect(result.stackTrace, same(trace));
    });

    test('parsing and validation errors are invalidData', () {
      expect(
        toAppException(const FormatException('x')).code,
        AppErrorCode.invalidData,
      );
      expect(toAppException(ArgumentError('x')).code, AppErrorCode.invalidData);
    });

    test('AppException passes through unchanged', () {
      const original = AppException(AppErrorCode.notFound);
      expect(toAppException(original), same(original));
    });

    test('anything else is unknown', () {
      expect(toAppException(StateError('x')).code, AppErrorCode.unknown);
    });
  });
}
