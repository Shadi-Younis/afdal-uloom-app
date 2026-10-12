import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/halaqa.dart';
import '../models/user_role.dart';
import '../providers/repository_providers.dart';
import 'session_providers.dart';

/// A student and the halaqa they are in.
typedef StudentInHalaqa = ({AppUser student, Halaqa halaqa});

/// The halaqat the signed-in user works with, by name: a teacher's own,
/// every halaqa for an admin, none for a student.
final myHalaqatProvider = StreamProvider.autoDispose<List<Halaqa>>((ref) {
  final session = ref.watch(sessionProvider.select((s) => s.value));
  final halaqat = ref.watch(halaqaRepositoryProvider);
  return switch (session?.role) {
    UserRole.admin => halaqat.watchAll(),
    UserRole.teacher => halaqat.watchForTeacher(session!.uid),
    _ => Stream.value(const []),
  };
});

/// The students of halaqa [halaqaId], by name (disabled ones included).
final halaqaStudentsProvider = StreamProvider.autoDispose
    .family<List<AppUser>, String>(
      (ref, halaqaId) =>
          ref.watch(userRepositoryProvider).watchStudentsInHalaqa(halaqaId),
    );

/// Every student of [myHalaqatProvider] with their halaqa, by name: the
/// students a teacher (or admin) may upload recordings for. Disabled
/// students are included; callers decide.
final myStudentsProvider =
    Provider.autoDispose<AsyncValue<List<StudentInHalaqa>>>((ref) {
      final halaqat = ref.watch(myHalaqatProvider);
      if (halaqat case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      final list = halaqat.value;
      if (list == null) return const AsyncLoading();
      final students = <StudentInHalaqa>[];
      for (final halaqa in list) {
        switch (ref.watch(halaqaStudentsProvider(halaqa.id))) {
          case AsyncError(:final error, :final stackTrace):
            return AsyncError(error, stackTrace);
          case AsyncData(:final value):
            students.addAll([
              for (final student in value) (student: student, halaqa: halaqa),
            ]);
          default:
            return const AsyncLoading();
        }
      }
      students.sort((a, b) => a.student.fullName.compareTo(b.student.fullName));
      return AsyncData(students);
    });
