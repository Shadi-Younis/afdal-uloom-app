import 'dart:async';

import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/change_halaqa_teacher_controller.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/create_halaqa_controller.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/input_error.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/input_field.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/rename_halaqa_controller.dart';
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

  group('CreateHalaqaController', () {
    setUp(() => container.listen(createHalaqaControllerProvider, (_, _) {}));
    CreateHalaqaController controller() =>
        container.read(createHalaqaControllerProvider.notifier);

    test('success returns the new id, name trimmed', () async {
      final id = await controller().submit(
        name: ' حلقة الضحى ',
        teacherId: 't02',
      );
      expect(id, isNotNull);
      expect(school.halaqat.createCalls.single, ('حلقة الضحى', 't02'));
      expect(school.halaqat.halaqat[id]?.name, 'حلقة الضحى');
    });

    test('name 1..60 and a teacher are required', () async {
      await controller().submit(name: '  ', teacherId: null);
      expect(container.read(createHalaqaControllerProvider).fieldErrors, {
        InputField.halaqaName: InputError.required,
        InputField.teacher: InputError.required,
      });

      await controller().submit(name: 'ح' * 61, teacherId: 't01');
      expect(
        container
            .read(createHalaqaControllerProvider)
            .errorOf(InputField.halaqaName),
        InputError.tooLong,
      );
      expect(school.halaqat.createCalls, isEmpty);

      expect(
        await controller().submit(name: 'ح' * 60, teacherId: 't01'),
        isNotNull,
      );
    });

    test('a refused write is the form error', () async {
      school.halaqat.writeError = const AppException(
        AppErrorCode.permissionDenied,
      );
      expect(await controller().submit(name: 'حلقة', teacherId: 't01'), isNull);
      expect(
        container.read(createHalaqaControllerProvider).error?.code,
        AppErrorCode.permissionDenied,
      );
    });
  });

  group('RenameHalaqaController', () {
    setUp(() => container.listen(renameHalaqaControllerProvider, (_, _) {}));
    RenameHalaqaController controller() =>
        container.read(renameHalaqaControllerProvider.notifier);

    test('success renames, trimmed', () async {
      expect(await controller().rename('halaqa-fajr', ' حلقة الشروق '), isTrue);
      expect(school.halaqat.renameCalls.single, ('halaqa-fajr', 'حلقة الشروق'));
    });

    test('an empty name is refused before the call', () async {
      expect(await controller().rename('halaqa-fajr', ''), isFalse);
      expect(
        container
            .read(renameHalaqaControllerProvider)
            .errorOf(InputField.halaqaName),
        InputError.required,
      );
      expect(school.halaqat.renameCalls, isEmpty);
    });

    test('a network error is the form error', () async {
      school.halaqat.writeError = const AppException(AppErrorCode.network);
      expect(await controller().rename('halaqa-fajr', 'حلقة'), isFalse);
      expect(
        container.read(renameHalaqaControllerProvider).error?.code,
        AppErrorCode.network,
      );
    });
  });

  group('ChangeHalaqaTeacherController', () {
    final provider = changeHalaqaTeacherControllerProvider('halaqa-fajr');
    setUp(() => container.listen(provider, (_, _) {}));

    test('success calls changeHalaqaTeacher for its halaqa', () async {
      expect(await container.read(provider.notifier).change('t02'), isTrue);
      expect(school.accounts.changeTeacherCalls.single, ('halaqa-fajr', 't02'));
      expect(container.read(provider), const AsyncData<void>(null));
    });

    test('loading while running, error state on failure', () async {
      school.accounts
        ..gate = Completer()
        ..error = const AppException(AppErrorCode.failedPrecondition);
      final pending = container.read(provider.notifier).change('t02');
      expect(container.read(provider).isLoading, isTrue);
      expect(await container.read(provider.notifier).change('t02'), isFalse);

      school.accounts.gate!.complete();
      expect(await pending, isFalse);
      expect(
        container.read(provider).error,
        isA<AppException>().having(
          (e) => e.code,
          'code',
          AppErrorCode.failedPrecondition,
        ),
      );
      expect(school.accounts.changeTeacherCalls, hasLength(1));
    });
  });
}
