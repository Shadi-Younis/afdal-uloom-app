import 'dart:async';

import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/providers/service_providers.dart';
import 'package:afdal_uloom_tilawat/features/account/application/change_password_controller.dart';
import 'package:afdal_uloom_tilawat/features/account/application/change_password_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_auth_service.dart';

void main() {
  late FakeAuthService auth;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthService(
      initial: const AuthSession(uid: 't01', role: UserRole.teacher),
    );
    container = ProviderContainer.test(
      overrides: [authServiceProvider.overrideWithValue(auth)],
    );
    container.listen(changePasswordControllerProvider, (_, _) {});
  });

  ChangePasswordController controller() =>
      container.read(changePasswordControllerProvider.notifier);
  ChangePasswordState state() =>
      container.read(changePasswordControllerProvider);

  Future<bool> submit(String current, String next, [String? confirm]) =>
      controller().submit(
        current: current,
        next: next,
        confirm: confirm ?? next,
      );

  test('success: changePassword with both passwords', () async {
    expect(await submit('old-pass', 'new pass 1'), isTrue);
    expect(auth.changePasswordCalls.single, ('old-pass', 'new pass 1'));
    expect(state(), const ChangePasswordState());
  });

  test(
    'empty fields, a short or long new one, a different confirmation',
    () async {
      expect(await submit('', ''), isFalse);
      expect(
        state().problemOf(PasswordInput.current),
        PasswordProblem.required,
      );
      expect(state().problemOf(PasswordInput.next), PasswordProblem.required);

      await submit('old', '12345');
      expect(state().problemOf(PasswordInput.current), isNull);
      expect(state().problemOf(PasswordInput.next), PasswordProblem.length);

      await submit('old', 'a' * 65);
      expect(state().problemOf(PasswordInput.next), PasswordProblem.length);

      await submit('old', 'new-pass', 'new-pas');
      expect(state().problemOf(PasswordInput.next), isNull);
      expect(
        state().problemOf(PasswordInput.confirm),
        PasswordProblem.mismatch,
      );
      expect(auth.changePasswordCalls, isEmpty);
    },
  );

  test('a wrong current password goes next to that field', () async {
    auth.changePasswordError = const AppException(AppErrorCode.wrongPassword);
    expect(await submit('wrong', 'new-pass'), isFalse);
    expect(state().problemOf(PasswordInput.current), PasswordProblem.wrong);

    controller().edited(PasswordInput.current);
    expect(state().problemOf(PasswordInput.current), isNull);
  });

  test('a weak new password goes next to that field', () async {
    auth.changePasswordError = const AppException(AppErrorCode.weakPassword);
    expect(await submit('old-pass', 'abcdef'), isFalse);
    expect(state().problemOf(PasswordInput.next), PasswordProblem.weak);
  });

  for (final code in [
    AppErrorCode.network,
    AppErrorCode.tooManyAttempts,
    AppErrorCode.permissionDenied,
  ]) {
    test('${code.name} is the form error', () async {
      auth.changePasswordError = AppException(code);
      expect(await submit('old-pass', 'new-pass'), isFalse);
      expect(state().error?.code, code);
      expect(state().problems, isEmpty);
    });
  }

  test(
    'submitting while the call runs; a second submit does nothing',
    () async {
      auth.changePasswordGate = Completer();
      final first = submit('old-pass', 'new-pass');
      expect(state().submitting, isTrue);
      expect(await submit('old-pass', 'new-pass'), isFalse);
      auth.changePasswordGate!.complete();
      expect(await first, isTrue);
      expect(auth.changePasswordCalls, hasLength(1));
    },
  );
}
