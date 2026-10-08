import 'package:afdal_uloom_tilawat/core/models/app_user.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 10, 1, 8);
  final student = AppUser(
    id: 'u1',
    username: 's023',
    fullName: 'أحمد علي',
    role: UserRole.student,
    studentCode: 'S023',
    halaqaId: 'h1',
    fcmTokens: const ['token-a'],
    createdAt: createdAt,
  );

  test('toMap uses the contract field names and leaves out the id', () {
    expect(student.toMap(), {
      'username': 's023',
      'fullName': 'أحمد علي',
      'role': 'student',
      'studentCode': 'S023',
      'halaqaId': 'h1',
      'fcmTokens': ['token-a'],
      'createdAt': createdAt,
      'disabled': false,
    });
  });

  test('round trip through toMap and fromMap', () {
    expect(AppUser.fromMap('u1', student.toMap()), student);
  });

  test('a teacher has no student fields, and fcmTokens defaults to empty', () {
    final teacher = AppUser.fromMap('t1', {
      'username': 't01',
      'fullName': 'المعلم',
      'role': 'teacher',
      'createdAt': createdAt,
    });
    expect(teacher.studentCode, isNull);
    expect(teacher.halaqaId, isNull);
    expect(teacher.fcmTokens, isEmpty);
  });

  test('disabled defaults to false, also when the field is missing', () {
    expect(student.disabled, isFalse);
    final map = student.toMap()..remove('disabled');
    expect(AppUser.fromMap('u1', map).disabled, isFalse);
  });

  test('disabled round trips, and must be a bool', () {
    final disabled = student.copyWith(disabled: true);
    expect(disabled.toMap()['disabled'], isTrue);
    expect(AppUser.fromMap('u1', disabled.toMap()), disabled);
    expect(
      () => AppUser.fromMap('u1', {...student.toMap(), 'disabled': 'yes'}),
      throwsFormatException,
    );
  });

  test('fcmTokens from fromMap cannot be modified', () {
    final user = AppUser.fromMap('u1', student.toMap());
    expect(() => user.fcmTokens.add('x'), throwsUnsupportedError);
  });

  test('missing required field throws FormatException', () {
    final map = student.toMap()..remove('fullName');
    expect(() => AppUser.fromMap('u1', map), throwsFormatException);
  });

  test('wrong type throws FormatException', () {
    expect(
      () => AppUser.fromMap('u1', {...student.toMap(), 'createdAt': 'today'}),
      throwsFormatException,
    );
    expect(
      () => AppUser.fromMap('u1', {
        ...student.toMap(),
        'fcmTokens': [1, 2],
      }),
      throwsFormatException,
    );
  });

  test('unknown role throws FormatException', () {
    expect(
      () => AppUser.fromMap('u1', {...student.toMap(), 'role': 'parent'}),
      throwsFormatException,
    );
  });

  test('copyWith, equality and hashCode', () {
    final renamed = student.copyWith(fullName: 'أحمد');
    expect(renamed.fullName, 'أحمد');
    expect(renamed.username, student.username);
    expect(renamed, isNot(student));
    expect(student.copyWith(), student);
    expect(student.copyWith().hashCode, student.hashCode);
    expect(student.copyWith(disabled: true), isNot(student));
    expect(student.toString(), contains('s023'));
  });
}
