import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/application/my_students_providers.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_digits.dart';
import '../../../../core/widgets/islamic/app_card.dart';
import '../../../../core/widgets/islamic/empty_state.dart';
import '../../../../core/widgets/islamic/error_state.dart';
import '../../../../core/widgets/islamic/loading_state.dart';

/// «حلقاتي»: the teacher's halaqat with their number of students; a tap
/// opens the halaqa (push: back returns home).
class TeacherHalaqatList extends ConsumerWidget {
  const TeacherHalaqatList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(myHalaqatProvider)) {
      AsyncData(value: final halaqat) when halaqat.isEmpty => const EmptyState(
        message: AppStrings.noTeacherHalaqat,
      ),
      AsyncData(value: final halaqat) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final halaqa in halaqat)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spaceS),
              child: AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.mosque_outlined),
                  ),
                  title: Text(halaqa.name),
                  subtitle: _StudentCount(halaqaId: halaqa.id),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => context.push(AppRoutes.teacherHalaqa(halaqa.id)),
                ),
              ),
            ),
        ],
      ),
      AsyncError(:final error) => ErrorState(
        error: error,
        onRetry: () => ref.invalidate(myHalaqatProvider),
      ),
      _ => const LoadingState(),
    };
  }
}

class _StudentCount extends ConsumerWidget {
  const _StudentCount({required this.halaqaId});

  final String halaqaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(halaqaStudentsProvider(halaqaId)).value;
    return Text(
      students == null
          ? ''
          : AppStrings.studentCount(toArabicDigits(students.length)),
    );
  }
}
