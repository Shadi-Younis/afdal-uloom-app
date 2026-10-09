import 'dart:async';

import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/delete_halaqa_controller.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/delete_user_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';

void main() {
  late AdminFixture school;
  late ProviderContainer container;

  setUp(() {
    school = AdminFixture();
    container = school.container();
  });

  AppErrorCode? errorCodeOf(ProviderListenable<AsyncValue<void>> provider) =>
      (container.read(provider).error as AppException?)?.code;

  group('DeleteHalaqaController', () {
    final provider = deleteHalaqaControllerProvider('halaqa-asr');
    setUp(() => container.listen(provider, (_, _) {}));
    DeleteHalaqaController controller() => container.read(provider.notifier);

    test('success: deleteHalaqa, and the halaqat stream drops it', () async {
      expect(await controller().delete(), isTrue);
      expect(school.accounts.deleteHalaqaCalls, ['halaqa-asr']);
      expect(school.halaqat.halaqat.containsKey('halaqa-asr'), isFalse);
      expect(container.read(provider), const AsyncData<void>(null));
    });

    test('loading while the call runs; a second tap does nothing', () async {
      school.accounts.gate = Completer();
      final first = controller().delete();
      expect(container.read(provider).isLoading, isTrue);
      expect(await controller().delete(), isFalse);
      school.accounts.gate!.complete();
      expect(await first, isTrue);
      expect(school.accounts.deleteHalaqaCalls, hasLength(1));
    });

    for (final code in [
      AppErrorCode.halaqaHasStudents,
      AppErrorCode.halaqaHasRecordings,
      AppErrorCode.network,
      AppErrorCode.permissionDenied,
    ]) {
      test('refused (${code.name}): false, the error in the state', () async {
        school.accounts.error = AppException(code);
        expect(await controller().delete(), isFalse);
        expect(errorCodeOf(provider), code);
        expect(school.halaqat.halaqat.containsKey('halaqa-asr'), isTrue);
      });
    }

    test('an error that is not an AppException is wrapped', () async {
      school.accounts.error = StateError('boom');
      expect(await controller().delete(), isFalse);
      expect(errorCodeOf(provider), AppErrorCode.unknown);
    });
  });

  group('DeleteUserController', () {
    final provider = deleteUserControllerProvider('s001');
    setUp(() => container.listen(provider, (_, _) {}));
    DeleteUserController controller() => container.read(provider.notifier);

    test(
      'success: the number of deleted recordings; the user is gone',
      () async {
        school.accounts.recordingsDeleted = 3;
        expect(await controller().delete(), 3);
        expect(school.accounts.deleteUserCalls, ['s001']);
        expect(school.users.users.containsKey('s001'), isFalse);
      },
    );

    test('a teacher without recordings: 0', () async {
      final teacher = deleteUserControllerProvider('t03');
      container.listen(teacher, (_, _) {});
      expect(await container.read(teacher.notifier).delete(), 0);
      expect(school.users.users.containsKey('t03'), isFalse);
    });

    for (final code in [
      AppErrorCode.teacherOwnsHalaqat,
      AppErrorCode.permissionDenied,
      AppErrorCode.notFound,
      AppErrorCode.network,
    ]) {
      test('refused (${code.name}): null, the error in the state', () async {
        school.accounts.error = AppException(code);
        expect(await controller().delete(), isNull);
        expect(errorCodeOf(provider), code);
        expect(school.users.users.containsKey('s001'), isTrue);
      });
    }

    test('loading while the call runs; a second tap does nothing', () async {
      school.accounts.gate = Completer();
      final first = controller().delete();
      expect(container.read(provider).isLoading, isTrue);
      expect(await controller().delete(), isNull);
      school.accounts.gate!.complete();
      expect(await first, 0);
      expect(school.accounts.deleteUserCalls, hasLength(1));
    });
  });

  group('DeleteUserController.confirms', () {
    test('only the exact code confirms', () {
      expect(DeleteUserController.confirms('S014', 'S014'), isTrue);
      expect(DeleteUserController.confirms('s014', 'S014'), isFalse);
      expect(DeleteUserController.confirms(' S014', 'S014'), isFalse);
      expect(DeleteUserController.confirms('S014 ', 'S014'), isFalse);
      expect(DeleteUserController.confirms('S01', 'S014'), isFalse);
      expect(DeleteUserController.confirms('', 'S014'), isFalse);
      expect(DeleteUserController.confirms('', ''), isFalse);
    });
  });
}
