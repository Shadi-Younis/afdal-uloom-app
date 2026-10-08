import 'package:afdal_uloom_tilawat/core/data/firestore_mapping.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toFirestore turns DateTime into Timestamp, leaves the rest', () {
    final at = DateTime(2026, 10, 5, 16, 30);
    expect(toFirestore({'at': at, 'n': 1, 'none': null}), {
      'at': Timestamp.fromDate(at),
      'n': 1,
      'none': null,
    });
  });

  test('readDocument turns Timestamp into DateTime', () async {
    final db = FakeFirebaseFirestore();
    final at = DateTime(2026, 10, 5, 16, 30);
    await db.doc('x/1').set({'createdAt': Timestamp.fromDate(at), 'n': 1});
    expect(readDocument(await db.doc('x/1').get()), {'createdAt': at, 'n': 1});
  });

  test('guard rethrows a FirebaseException as AppException', () async {
    await expectLater(
      guard<void>(
        () async => throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        ),
      ),
      throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          AppErrorCode.permissionDenied,
        ),
      ),
    );
  });

  test('guardStream turns error events into AppException', () async {
    final stream = guardStream(
      Stream<int>.error(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      ),
    );
    await expectLater(
      stream,
      emitsError(
        isA<AppException>().having((e) => e.code, 'code', AppErrorCode.network),
      ),
    );
  });
}
