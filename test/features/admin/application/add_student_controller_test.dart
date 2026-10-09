import 'dart:async';

import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/add_student_controller.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/form_submit_state.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/input_error.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/input_field.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/issued_credentials.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';

void main() {
  late AdminFixture school;
  late ProviderContainer container;

  setUp(() {
    school = AdminFixture();
    container = school.container();
    container.listen(addStudentControllerProvider, (_, _) {});
  });

  AddStudentController controller() =>
      container.read(addStudentControllerProvider.notifier);
  FormSubmitState state() => container.read(addStudentControllerProvider);

  Future<IssuedCredentials?> submit({
    String fullName = 'زيد قاسم',
    String username = 's013',
    String password = 'k7m2xq4p',
    String studentCode = 'S013',
    String? halaqaId = 'halaqa-fajr',
  }) => controller().submit(
    fullName: fullName,
    username: username,
    password: password,
    studentCode: studentCode,
    halaqaId: halaqaId,
  );

  test('success: createUser as a student, credentials to show', () async {
    final credentials = await submit(
      fullName: '  زيد قاسم ',
      username: ' S013 ',
      studentCode: ' s013',
    );
    expect(school.accounts.createUserCalls.single, {
      'username': 's013',
      'password': 'k7m2xq4p',
      'fullName': 'زيد قاسم',
      'role': UserRole.student,
      'halaqaId': 'halaqa-fajr',
      'studentCode': 'S013',
    });
    expect(
      credentials,
      const IssuedCredentials(
        fullName: 'زيد قاسم',
        username: 's013',
        password: 'k7m2xq4p',
        role: UserRole.student,
      ),
    );
    expect(state(), const FormSubmitState());
  });

  test('every field is validated before calling the server', () async {
    final result = await submit(
      fullName: 'ز',
      username: 'زيد',
      password: '12345',
      studentCode: 'X1',
      halaqaId: null,
    );
    expect(result, isNull);
    expect(state().fieldErrors, {
      InputField.fullName: InputError.tooShort,
      InputField.username: InputError.invalidCharacters,
      InputField.password: InputError.tooShort,
      InputField.studentCode: InputError.invalidFormat,
      InputField.halaqa: InputError.required,
    });
    expect(school.accounts.createUserCalls, isEmpty);
  });

  test('empty fields are required', () async {
    await submit(fullName: ' ', username: '', password: '', studentCode: '');
    expect(state().fieldErrors.values.toSet(), {InputError.required});
    expect(state().fieldErrors, hasLength(4));
  });

  test('a taken username goes next to the username field', () async {
    school.accounts.error = const AppException(AppErrorCode.usernameTaken);
    expect(await submit(), isNull);
    expect(state().errorOf(InputField.username), InputError.taken);
    expect(state().error, isNull);
  });

  test('a taken student code goes next to the code field', () async {
    school.accounts.error = const AppException(AppErrorCode.studentCodeTaken);
    await submit();
    expect(state().errorOf(InputField.studentCode), InputError.taken);
  });

  for (final code in [
    AppErrorCode.network,
    AppErrorCode.invalidData,
    AppErrorCode.permissionDenied,
  ]) {
    test('${code.name} is the form error', () async {
      school.accounts.error = AppException(code);
      await submit();
      expect(state().error?.code, code);
      expect(state().fieldErrors, isEmpty);
      expect(state().submitting, isFalse);
    });
  }

  test('a non-AppException becomes unknown, never raw', () async {
    school.accounts.error = StateError('boom');
    await submit();
    expect(state().error?.code, AppErrorCode.unknown);
  });

  test('submitting while the call runs; a second submit is ignored', () async {
    school.accounts.gate = Completer();
    final pending = submit();
    expect(state().submitting, isTrue);
    expect(await submit(), isNull);
    expect(school.accounts.createUserCalls, hasLength(1));

    school.accounts.gate!.complete();
    expect(await pending, isNotNull);
    expect(state().submitting, isFalse);
  });

  test('editing a field clears its error and the form error', () async {
    school.accounts.error = const AppException(AppErrorCode.usernameTaken);
    await submit(fullName: '');
    controller().edited(InputField.username);
    expect(state().errorOf(InputField.username), isNull);
    expect(state().errorOf(InputField.fullName), InputError.required);
  });

  test('suggests an 8-character password, a new one each time', () {
    final first = controller().suggestPassword();
    expect(first, hasLength(8));
    expect(controller().suggestPassword(), isNot(first));
  });
}
