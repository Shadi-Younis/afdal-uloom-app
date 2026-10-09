import 'dart:async';

import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/app_user.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/edit_profile_controller.dart';
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
    container.listen(editProfileControllerProvider, (_, _) {});
  });

  EditProfileController controller() =>
      container.read(editProfileControllerProvider.notifier);
  FormSubmitState state() => container.read(editProfileControllerProvider);
  AppUser user(String uid) => school.users.users[uid]!;

  test('sends only the changed fields, normalized', () async {
    final saved = await controller().save(
      user('s001'),
      fullName: '  أحمد الخطيب ',
      username: ' Ahmed.K ',
      studentCode: 's150',
    );
    expect(saved, isTrue);
    expect(school.accounts.updateProfileCalls.single, {
      'uid': 's001',
      'username': 'ahmed.k',
      'studentCode': 'S150',
    });
    expect(user('s001').username, 'ahmed.k');
    expect(state(), const FormSubmitState());
  });

  test('nothing changed: saved without a call', () async {
    expect(
      await controller().save(
        user('t01'),
        fullName: 'الشيخ محمود',
        username: 't01',
      ),
      isTrue,
    );
    expect(school.accounts.updateProfileCalls, isEmpty);
  });

  test('a teacher has no code to send, whatever is typed', () async {
    await controller().save(
      user('t01'),
      fullName: 'الشيخ محمود الجديد',
      username: 't01',
      studentCode: 'S999',
    );
    expect(school.accounts.updateProfileCalls.single, {
      'uid': 't01',
      'fullName': 'الشيخ محمود الجديد',
    });
  });

  test('invalid input: errors next to the fields, no call', () async {
    final saved = await controller().save(
      user('s001'),
      fullName: 'ا',
      username: 'a b',
      studentCode: 'X12',
    );
    expect(saved, isFalse);
    expect(state().errorOf(InputField.fullName), InputError.tooShort);
    expect(state().errorOf(InputField.username), InputError.invalidCharacters);
    expect(state().errorOf(InputField.studentCode), InputError.invalidFormat);
    expect(school.accounts.updateProfileCalls, isEmpty);

    controller().edited(InputField.username);
    expect(state().errorOf(InputField.username), isNull);
    expect(state().errorOf(InputField.fullName), InputError.tooShort);
  });

  test('a taken username or code goes next to its field', () async {
    school.accounts.error = const AppException(AppErrorCode.usernameTaken);
    expect(
      await controller().save(
        user('s001'),
        fullName: 'أحمد الخطيب',
        username: 's002',
      ),
      isFalse,
    );
    expect(state().errorOf(InputField.username), InputError.taken);

    school.accounts.error = const AppException(AppErrorCode.studentCodeTaken);
    await controller().save(
      user('s001'),
      fullName: 'أحمد الخطيب',
      username: 's001',
      studentCode: 'S002',
    );
    expect(state().errorOf(InputField.studentCode), InputError.taken);
  });

  test('a network error is the form error', () async {
    school.accounts.error = const AppException(AppErrorCode.network);
    expect(
      await controller().save(
        user('t01'),
        fullName: 'اسم آخر',
        username: 't01',
      ),
      isFalse,
    );
    expect(state().error?.code, AppErrorCode.network);
  });

  test('submitting while the call runs; a second save does nothing', () async {
    school.accounts.gate = Completer();
    final first = controller().save(
      user('t01'),
      fullName: 'اسم آخر',
      username: 't01',
    );
    expect(state().submitting, isTrue);
    expect(
      await controller().save(user('t01'), fullName: 'x y', username: 't01'),
      isFalse,
    );
    school.accounts.gate!.complete();
    expect(await first, isTrue);
    expect(school.accounts.updateProfileCalls, hasLength(1));
  });
}
