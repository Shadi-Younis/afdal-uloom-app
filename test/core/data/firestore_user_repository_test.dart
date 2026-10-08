import 'package:afdal_uloom_tilawat/core/data/firestore_user_repository.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreUserRepository repository;
  final createdAt = DateTime(2026, 10, 1, 8);

  Future<void> addUser(
    String uid,
    String fullName,
    UserRole role, {
    String? halaqaId,
    List<String> fcmTokens = const [],
  }) => db.doc('users/$uid').set({
    'username': uid,
    'fullName': fullName,
    'role': role.value,
    'studentCode': role == UserRole.student ? uid.toUpperCase() : null,
    'halaqaId': halaqaId,
    'fcmTokens': fcmTokens,
    'createdAt': Timestamp.fromDate(createdAt),
  });

  setUp(() async {
    db = FakeFirebaseFirestore();
    repository = FirestoreUserRepository(db);
    await addUser('t1', 'معلم', UserRole.teacher);
    await addUser('s1', 'يوسف', UserRole.student, halaqaId: 'h1');
    await addUser('s2', 'أحمد', UserRole.student, halaqaId: 'h1');
    await addUser('s3', 'بلال', UserRole.student, halaqaId: 'h2');
  });

  test('watchUser maps the document, Timestamp to DateTime', () async {
    final user = await repository.watchUser('s1').first;
    expect(user!.id, 's1');
    expect(user.fullName, 'يوسف');
    expect(user.role, UserRole.student);
    expect(user.halaqaId, 'h1');
    expect(user.createdAt, createdAt);
  });

  test('watchUser emits null for a missing user', () async {
    expect(await repository.watchUser('nobody').first, isNull);
  });

  test('watchStudentsInHalaqa: only that halaqa, sorted by fullName', () async {
    final students = await repository.watchStudentsInHalaqa('h1').first;
    expect(students.map((u) => u.id), ['s2', 's1']); // أحمد before يوسف
  });

  test('watchUsersByRole: only that role, sorted by fullName', () async {
    final students = await repository.watchUsersByRole(UserRole.student).first;
    expect(students.map((u) => u.fullName), ['أحمد', 'بلال', 'يوسف']);
    final teachers = await repository.watchUsersByRole(UserRole.teacher).first;
    expect(teachers.map((u) => u.id), ['t1']);
  });

  test('addFcmToken adds once, removeFcmToken removes', () async {
    await repository.addFcmToken('s1', 'a');
    await repository.addFcmToken('s1', 'a');
    await repository.addFcmToken('s1', 'b');
    expect((await repository.watchUser('s1').first)!.fcmTokens, ['a', 'b']);

    await repository.removeFcmToken('s1', 'a');
    await repository.removeFcmToken('s1', 'missing');
    expect((await repository.watchUser('s1').first)!.fcmTokens, ['b']);
  });

  test('a malformed document becomes AppException(invalidData)', () async {
    await db.doc('users/bad').set({'username': 'bad', 'role': 'parent'});
    await expectLater(
      repository.watchUser('bad'),
      emitsError(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          AppErrorCode.invalidData,
        ),
      ),
    );
  });
}
