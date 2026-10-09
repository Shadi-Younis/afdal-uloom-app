import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/halaqa.dart';
import '../../../core/utils/async_value_combine.dart';
import 'admin_data_providers.dart';

/// The counts on the admin's home screen. Disabled accounts are not
/// counted.
class AdminOverview {
  const AdminOverview({
    required this.halaqat,
    required this.activeTeachers,
    required this.activeStudents,
  });

  factory AdminOverview.from(
    List<Halaqa> halaqat,
    List<AppUser> teachers,
    List<AppUser> students,
  ) => AdminOverview(
    halaqat: halaqat.length,
    activeTeachers: teachers.where((t) => !t.disabled).length,
    activeStudents: students.where((s) => !s.disabled).length,
  );

  final int halaqat;
  final int activeTeachers;
  final int activeStudents;

  @override
  bool operator ==(Object other) =>
      other is AdminOverview &&
      other.halaqat == halaqat &&
      other.activeTeachers == activeTeachers &&
      other.activeStudents == activeStudents;

  @override
  int get hashCode => Object.hash(halaqat, activeTeachers, activeStudents);

  @override
  String toString() =>
      'AdminOverview($halaqat halaqat, $activeTeachers teachers, '
      '$activeStudents students)';
}

final adminOverviewProvider = Provider.autoDispose<AsyncValue<AdminOverview>>(
  (ref) => combine3(
    ref.watch(adminHalaqatProvider),
    ref.watch(adminTeachersProvider),
    ref.watch(adminStudentsProvider),
    AdminOverview.from,
  ),
);
