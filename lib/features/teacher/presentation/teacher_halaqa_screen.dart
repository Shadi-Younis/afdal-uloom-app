import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/application/my_students_providers.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/common/content_width.dart';
import '../../../core/widgets/common/student_tile.dart';
import '../../../core/widgets/islamic/app_card.dart';
import '../../../core/widgets/islamic/app_page_scaffold.dart';
import '../../../core/widgets/islamic/empty_state.dart';
import '../../../core/widgets/islamic/error_state.dart';
import '../../../core/widgets/islamic/loading_state.dart';
import '../application/teacher_providers.dart';

/// One of the teacher's halaqat: its students; a tap opens the student.
class TeacherHalaqaScreen extends ConsumerWidget {
  const TeacherHalaqaScreen({super.key, required this.halaqaId});

  final String halaqaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final halaqa = ref.watch(teacherHalaqaProvider(halaqaId));
    final students = ref.watch(halaqaStudentsProvider(halaqaId));
    void retry() => ref
      ..invalidate(teacherHalaqaProvider(halaqaId))
      ..invalidate(halaqaStudentsProvider(halaqaId));
    return AppPageScaffold(
      title: halaqa.value?.name ?? AppStrings.myHalaqat,
      body: switch ((halaqa, students)) {
        (AsyncError(:final error), _) => ErrorState(
          error: error,
          onRetry: retry,
        ),
        (_, AsyncError(:final error)) => ErrorState(
          error: error,
          onRetry: retry,
        ),
        (AsyncData(value: null), _) => const ErrorState(
          error: AppException(AppErrorCode.notFound),
        ),
        (AsyncData(), AsyncData(value: final list)) when list.isEmpty =>
          const EmptyState(message: AppStrings.noStudentsInHalaqa),
        (AsyncData(), AsyncData(value: final list)) => ListView.separated(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSizes.spaceS),
          itemBuilder: (context, i) => ContentWidth(
            child: AppCard(
              padding: EdgeInsets.zero,
              child: StudentTile(
                student: list[i],
                onTap: () => context.push(
                  AppRoutes.teacherStudent(halaqaId, list[i].id),
                ),
              ),
            ),
          ),
        ),
        _ => const LoadingState(),
      },
    );
  }
}
