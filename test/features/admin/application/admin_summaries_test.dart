import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/halaqa.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/add_student_controller.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/admin_data_providers.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/admin_overview.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/halaqa_summary.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/student_summary.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/students_filter_controller.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/teacher_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/fake_user_repository.dart';

void main() {
  late AdminFixture school;
  late ProviderContainer container;

  setUp(() {
    school = AdminFixture();
    container = school.container();
  });

  /// Listens to [provider] and waits until the streams have delivered.
  Future<T> read<T>(ProviderListenable<AsyncValue<T>> provider) async {
    container.listen(provider, (_, _) {});
    await pumpEventQueue();
    return container.read(provider).requireValue;
  }

  group('overview', () {
    test('counts halaqat, and only active teachers and students', () async {
      expect(
        await read(adminOverviewProvider),
        const AdminOverview(halaqat: 2, activeTeachers: 2, activeStudents: 3),
      );
    });

    test('updates live when a student is added', () async {
      await read(adminOverviewProvider);
      school.users.put(seedStudent('s013', 'زيد', 'halaqa-asr'));
      await pumpEventQueue();
      expect(
        container.read(adminOverviewProvider).requireValue.activeStudents,
        4,
      );
    });

    test('loading until every stream has data; an error wins', () async {
      expect(container.read(adminOverviewProvider), isA<AsyncLoading>());

      school.halaqat.watchError = const AppException(AppErrorCode.network);
      final failing = school.container();
      failing.listen(adminOverviewProvider, (_, _) {});
      await pumpEventQueue();
      expect(
        failing.read(adminOverviewProvider).error,
        isA<AppException>().having((e) => e.code, 'code', AppErrorCode.network),
      );
    });
  });

  group('halaqa summaries', () {
    test('teacher, students by code and active student count', () async {
      final summaries = await read(halaqaSummariesProvider);
      expect(summaries.map((s) => s.halaqa.name), ['حلقة العصر', 'حلقة الفجر']);

      final fajr = summaries[1];
      expect(fajr.teacher?.fullName, 'الشيخ محمود');
      expect(fajr.students.map((s) => s.studentCode), ['S001', 'S002', 'S012']);
      expect(fajr.activeStudentCount, 2);
    });

    test('one by id, null when it does not exist', () async {
      expect(
        (await read(halaqaSummaryProvider('halaqa-asr')))?.students.single.id,
        's003',
      );
      expect(await read(halaqaSummaryProvider('nope')), isNull);
    });

    test('a missing teacher profile gives a null teacher', () async {
      school.halaqat.put(
        const Halaqa(id: 'h-x', name: 'حلقة', teacherId: 'gone'),
      );
      expect((await read(halaqaSummaryProvider('h-x')))?.teacher, isNull);
    });
  });

  group('teacher summaries', () {
    test('each teacher with the halaqat they teach', () async {
      final summaries = await read(teacherSummariesProvider);
      final byId = {for (final s in summaries) s.teacher.id: s};
      expect(byId['t01']!.halaqat.map((h) => h.name), ['حلقة الفجر']);
      expect(byId['t03']!.halaqat, isEmpty);
      expect(byId['t03']!.teacher.disabled, isTrue);
    });

    test('active teachers leave out disabled ones', () async {
      final active = await read(activeTeachersProvider);
      expect(active.map((t) => t.id), unorderedEquals(['t01', 't02']));
    });

    test('the admin cannot disable their own account', () {
      expect(container.read(canDisableProvider('t01')), isTrue);
      container.listen(canDisableProvider('shadi'), (_, _) {});
      return pumpEventQueue().then(
        (_) => expect(container.read(canDisableProvider('shadi')), isFalse),
      );
    });
  });

  group('students', () {
    test('sorted by studentCode with their halaqa', () async {
      final students = await read(studentSummariesProvider);
      expect(students.map((s) => s.student.studentCode), [
        'S001',
        'S002',
        'S003',
        'S012',
      ]);
      expect(students[2].halaqa?.name, 'حلقة العصر');
    });

    test('S999 sorts before S1000', () {
      final a = seedStudent('s999', 'أ', 'h');
      final b = seedStudent('s1000', 'ب', 'h');
      expect(compareByStudentCode(a, b), lessThan(0));
    });

    test('search finds أحمد when typing احمد, and by code', () async {
      await read(filteredStudentsProvider);
      final filter = container.read(studentsFilterControllerProvider.notifier);

      filter.setQuery('احمد');
      expect(
        container
            .read(filteredStudentsProvider)
            .requireValue
            .map((s) => s.student.fullName),
        ['أحمد الخطيب'],
      );

      filter.setQuery('s003');
      expect(
        container.read(filteredStudentsProvider).requireValue.single.student.id,
        's003',
      );
    });

    test('halaqa chip and search combine; null shows all', () async {
      await read(filteredStudentsProvider);
      final filter = container.read(studentsFilterControllerProvider.notifier);

      filter.setHalaqa('halaqa-fajr');
      expect(
        container.read(filteredStudentsProvider).requireValue,
        hasLength(3),
      );

      filter.setQuery('عمر');
      expect(
        container.read(filteredStudentsProvider).requireValue.single.student.id,
        's002',
      );

      filter.setQuery('يوسف'); // in العصر
      expect(container.read(filteredStudentsProvider).requireValue, isEmpty);

      filter
        ..setQuery('')
        ..setHalaqa(null);
      expect(
        container.read(filteredStudentsProvider).requireValue,
        hasLength(4),
      );
    });

    test(
      'the suggested code is one above the highest, disabled included',
      () async {
        expect(await read(suggestedStudentCodeProvider), 'S013');
      },
    );
  });
}
