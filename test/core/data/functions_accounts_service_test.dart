import 'package:afdal_uloom_tilawat/core/data/functions_accounts_service.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher throwsAppError(AppErrorCode code) =>
    throwsA(isA<AppException>().having((e) => e.code, 'code', code));

void main() {
  late String calledName;
  late Object? calledData;

  FunctionsAccountsService serviceReturning(Object? result) =>
      FunctionsAccountsService.withCaller((name, data) async {
        calledName = name;
        calledData = data;
        return result;
      });

  FunctionsAccountsService serviceThrowing(String code, [Object? details]) =>
      FunctionsAccountsService.withCaller(
        (name, data) async => throw FirebaseFunctionsException(
          message: 'x',
          code: code,
          details: details,
        ),
      );

  test('createUser sends the role value and only the given fields', () async {
    final service = serviceReturning({'uid': 'new-uid'});

    final uid = await service.createUser(
      username: 't03',
      password: 'secret123',
      fullName: 'الشيخ أحمد',
      role: UserRole.teacher,
    );

    expect(uid, 'new-uid');
    expect(calledName, 'createUser');
    expect(calledData, {
      'username': 't03',
      'password': 'secret123',
      'fullName': 'الشيخ أحمد',
      'role': 'teacher',
    });

    await service.createUser(
      username: 's100',
      password: 'secret123',
      fullName: 'طالب',
      role: UserRole.student,
      halaqaId: 'h1',
      studentCode: 'S100',
    );
    expect(calledData, containsPair('halaqaId', 'h1'));
    expect(calledData, containsPair('studentCode', 'S100'));
  });

  test('the other callables send their arguments and read results', () async {
    final service = serviceReturning({'recordingsUpdated': 3});

    expect(await service.moveStudent(studentId: 's1', halaqaId: 'h2'), 3);
    expect(calledName, 'moveStudent');
    expect(calledData, {'studentId': 's1', 'halaqaId': 'h2'});

    expect(
      await service.changeHalaqaTeacher(halaqaId: 'h1', teacherId: 't2'),
      3,
    );
    expect(calledName, 'changeHalaqaTeacher');
    expect(calledData, {'halaqaId': 'h1', 'teacherId': 't2'});

    await service.resetPassword(uid: 's1', newPassword: 'new-pass');
    expect(calledName, 'resetPassword');
    expect(calledData, {'uid': 's1', 'newPassword': 'new-pass'});

    await service.setUserDisabled(uid: 's1', disabled: true);
    expect(calledName, 'setUserDisabled');
    expect(calledData, {'uid': 's1', 'disabled': true});
  });

  test('deleteHalaqa, deleteUser and updateUserProfile', () async {
    final service = serviceReturning({'recordingsDeleted': 4});

    await service.deleteHalaqa('h1');
    expect(calledName, 'deleteHalaqa');
    expect(calledData, {'halaqaId': 'h1'});

    expect(await service.deleteUser('s1'), 4);
    expect(calledName, 'deleteUser');
    expect(calledData, {'uid': 's1'});

    await service.updateUserProfile(uid: 's1', fullName: 'اسم');
    expect(calledName, 'updateUserProfile');
    expect(calledData, {'uid': 's1', 'fullName': 'اسم'});

    await service.updateUserProfile(
      uid: 's1',
      fullName: 'اسم',
      username: 'ali',
      studentCode: 'S150',
    );
    expect(calledData, {
      'uid': 's1',
      'fullName': 'اسم',
      'username': 'ali',
      'studentCode': 'S150',
    });
  });

  test('an unexpected result is invalidData', () async {
    await expectLater(
      serviceReturning({'nope': 1}).moveStudent(studentId: 's', halaqaId: 'h'),
      throwsAppError(AppErrorCode.invalidData),
    );
  });

  group('error codes', () {
    final expected = <(String, Object?), AppErrorCode>{
      ('permission-denied', null): AppErrorCode.permissionDenied,
      ('unauthenticated', null): AppErrorCode.permissionDenied,
      ('invalid-argument', null): AppErrorCode.invalidData,
      ('not-found', null): AppErrorCode.notFound,
      ('already-exists', {'field': 'username'}): AppErrorCode.usernameTaken,
      ('already-exists', {'field': 'studentCode'}):
          AppErrorCode.studentCodeTaken,
      ('failed-precondition', null): AppErrorCode.failedPrecondition,
      ('failed-precondition', {'reason': 'hasStudents'}):
          AppErrorCode.halaqaHasStudents,
      ('failed-precondition', {'reason': 'hasRecordings'}):
          AppErrorCode.halaqaHasRecordings,
      ('failed-precondition', {'reason': 'ownsHalaqat'}):
          AppErrorCode.teacherOwnsHalaqat,
      ('failed-precondition', {'reason': 'lastAdmin'}): AppErrorCode.lastAdmin,
      ('failed-precondition', {'reason': 'other'}):
          AppErrorCode.failedPrecondition,
      ('unavailable', null): AppErrorCode.network,
      ('internal', null): AppErrorCode.unknown,
    };
    for (final MapEntry(key: (code, details), value: appCode)
        in expected.entries) {
      test('$code $details -> ${appCode.name}', () async {
        await expectLater(
          serviceThrowing(
            code,
            details,
          ).setUserDisabled(uid: 's1', disabled: true),
          throwsAppError(appCode),
        );
      });
    }
  });
}
