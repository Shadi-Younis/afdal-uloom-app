import 'dart:async';

import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/providers/service_providers.dart';
import 'package:afdal_uloom_tilawat/features/auth/application/login_controller.dart';
import 'package:afdal_uloom_tilawat/features/auth/application/login_validation_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_auth_service.dart';

void main() {
  late FakeAuthService auth;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthService();
    container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(auth)],
    );
    // Keep the autoDispose controller alive for the whole test.
    container.listen(loginControllerProvider, (_, _) {});
  });
  tearDown(() => container.dispose());

  LoginController controller() =>
      container.read(loginControllerProvider.notifier);
  AsyncValue<void> state() => container.read(loginControllerProvider);

  test('starts idle', () {
    expect(state(), const AsyncData<void>(null));
  });

  group('validation', () {
    test('username is required (spaces do not count)', () async {
      await controller().signIn('   ', 'test1234');
      expect(state().error, LoginValidationError.usernameRequired);
      expect(auth.signInCalls, isEmpty);
    });

    test('password is required', () async {
      await controller().signIn('shadi', '');
      expect(state().error, LoginValidationError.passwordRequired);
      expect(auth.signInCalls, isEmpty);
    });
  });

  test('success calls AuthService with what was typed', () async {
    await controller().signIn('shadi', 'test1234');
    expect(auth.signInCalls, [('shadi', 'test1234')]);
    expect(state(), const AsyncData<void>(null));
  });

  test('is loading while signing in, and ignores a second submit', () async {
    auth.signInGate = Completer();
    final pending = controller().signIn('shadi', 'test1234');
    expect(state().isLoading, isTrue);

    await controller().signIn('shadi', 'test1234');
    expect(auth.signInCalls, hasLength(1));

    auth.signInGate!.complete();
    await pending;
    expect(state().isLoading, isFalse);
  });

  for (final code in [
    AppErrorCode.invalidCredentials,
    AppErrorCode.accountDisabled,
    AppErrorCode.tooManyAttempts,
    AppErrorCode.network,
    AppErrorCode.noRole,
  ]) {
    test('AuthService error ${code.name} becomes the error state', () async {
      auth.signInError = AppException(code);
      await controller().signIn('shadi', 'wrong');
      expect(
        state().error,
        isA<AppException>().having((e) => e.code, 'code', code),
      );
    });
  }

  test('a new attempt clears the previous error', () async {
    auth.signInError = const AppException(AppErrorCode.invalidCredentials);
    await controller().signIn('shadi', 'wrong');
    expect(state().hasError, isTrue);

    auth.signInError = null;
    await controller().signIn('shadi', 'test1234');
    expect(state().hasError, isFalse);
  });
}
