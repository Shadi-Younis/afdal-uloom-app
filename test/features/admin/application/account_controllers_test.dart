import 'dart:async';

import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/input_error.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/input_field.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/move_student_controller.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/reset_password_controller.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/set_user_disabled_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';

void main() {
  late AdminFixture school;
  late ProviderContainer container;

  setUp(() {
    school = AdminFixture();
    container = school.container();
  });

  group('ResetPasswordController', () {
    setUp(() => container.listen(resetPasswordControllerProvider, (_, _) {}));
    ResetPasswordController controller() =>
        container.read(resetPasswordControllerProvider.notifier);

    test('success: resetPassword, then the login details to show', () async {
      final student = school.users.users['s001']!;
      final credentials = await controller().reset(student, 'n3wpass22');
      expect(school.accounts.resetPasswordCalls.single, ('s001', 'n3wpass22'));
      expect(credentials?.username, 's001');
      expect(credentials?.fullName, 'أحمد الخطيب');
      expect(credentials?.password, 'n3wpass22');
      expect(credentials?.role, UserRole.student);
    });

    test('a short password is refused before the call', () async {
      expect(
        await controller().reset(school.users.users['t01']!, '123'),
        isNull,
      );
      expect(
        container
            .read(resetPasswordControllerProvider)
            .errorOf(InputField.password),
        InputError.tooShort,
      );
      expect(school.accounts.resetPasswordCalls, isEmpty);
    });

    test('a server error is the form error', () async {
      school.accounts.error = const AppException(AppErrorCode.permissionDenied);
      expect(
        await controller().reset(school.users.users['t01']!, 'abcdef23'),
        isNull,
      );
      expect(
        container.read(resetPasswordControllerProvider).error?.code,
        AppErrorCode.permissionDenied,
      );
    });
  });

  group('MoveStudentController', () {
    final provider = moveStudentControllerProvider('s001');
    setUp(() => container.listen(provider, (_, _) {}));

    test('success moves the student; the users stream shows it', () async {
      expect(
        await container.read(provider.notifier).move('halaqa-asr'),
        isTrue,
      );
      expect(school.accounts.moveStudentCalls.single, ('s001', 'halaqa-asr'));
      expect(school.users.users['s001']!.halaqaId, 'halaqa-asr');
      expect(container.read(provider), const AsyncData<void>(null));
    });

    test('a network error is the error state', () async {
      school.accounts.error = const AppException(AppErrorCode.network);
      expect(
        await container.read(provider.notifier).move('halaqa-asr'),
        isFalse,
      );
      expect(
        (container.read(provider).error! as AppException).code,
        AppErrorCode.network,
      );
    });
  });

  group('SetUserDisabledController', () {
    final provider = setUserDisabledControllerProvider('s002');
    setUp(() => container.listen(provider, (_, _) {}));

    test('disables, then enables again', () async {
      expect(await container.read(provider.notifier).setDisabled(true), isTrue);
      expect(school.users.users['s002']!.disabled, isTrue);
      expect(
        await container.read(provider.notifier).setDisabled(false),
        isTrue,
      );
      expect(school.accounts.setDisabledCalls, [
        ('s002', true),
        ('s002', false),
      ]);
    });

    test('loading while running; a second tap is ignored', () async {
      school.accounts.gate = Completer();
      final pending = container.read(provider.notifier).setDisabled(true);
      expect(container.read(provider).isLoading, isTrue);
      expect(
        await container.read(provider.notifier).setDisabled(true),
        isFalse,
      );
      school.accounts.gate!.complete();
      expect(await pending, isTrue);
      expect(school.accounts.setDisabledCalls, hasLength(1));
    });

    test('a refusal is the error state', () async {
      school.accounts.error = const AppException(AppErrorCode.permissionDenied);
      expect(
        await container.read(provider.notifier).setDisabled(true),
        isFalse,
      );
      expect(container.read(provider).hasError, isTrue);
      expect(school.users.users['s002']!.disabled, isFalse);
    });
  });
}
