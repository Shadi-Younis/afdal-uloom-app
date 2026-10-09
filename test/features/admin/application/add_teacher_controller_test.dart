import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/add_teacher_controller.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/form_submit_state.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/input_error.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/input_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';

void main() {
  late AdminFixture school;
  late ProviderContainer container;

  setUp(() {
    school = AdminFixture();
    container = school.container();
    container.listen(addTeacherControllerProvider, (_, _) {});
  });

  AddTeacherController controller() =>
      container.read(addTeacherControllerProvider.notifier);
  FormSubmitState state() => container.read(addTeacherControllerProvider);

  test('success: createUser as a teacher, without halaqa or code', () async {
    final credentials = await controller().submit(
      fullName: 'الشيخ أحمد',
      username: 'T03',
      password: 'abc23456',
    );
    expect(school.accounts.createUserCalls.single, {
      'username': 't03',
      'password': 'abc23456',
      'fullName': 'الشيخ أحمد',
      'role': UserRole.teacher,
      'halaqaId': null,
      'studentCode': null,
    });
    expect(credentials?.username, 't03');
    expect(credentials?.role, UserRole.teacher);
    expect(state(), const FormSubmitState());
  });

  test('validation errors, no call', () async {
    await controller().submit(
      fullName: 'ا' * 61,
      username: 'ab',
      password: 'x' * 65,
    );
    expect(state().fieldErrors, {
      InputField.fullName: InputError.tooLong,
      InputField.username: InputError.tooShort,
      InputField.password: InputError.tooLong,
    });
    expect(school.accounts.createUserCalls, isEmpty);
  });

  test('taken username and network errors', () async {
    school.accounts.error = const AppException(AppErrorCode.usernameTaken);
    await controller().submit(
      fullName: 'الشيخ أحمد',
      username: 't01',
      password: 'abc23456',
    );
    expect(state().errorOf(InputField.username), InputError.taken);

    school.accounts.error = const AppException(AppErrorCode.network);
    await controller().submit(
      fullName: 'الشيخ أحمد',
      username: 't03',
      password: 'abc23456',
    );
    expect(state().error?.code, AppErrorCode.network);
  });
}
