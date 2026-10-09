import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common/app_snack_bar.dart';
import '../../../../core/widgets/common/confirm_dialog.dart';
import '../../../../core/widgets/common/loading_button.dart';
import '../../application/admin_data_providers.dart';
import '../../application/move_student_controller.dart';
import '../../application/student_summary.dart';
import 'choice_dialog.dart';

/// "نقل إلى حلقة أخرى": pick a halaqa, confirm (recordings move with the
/// student), then moveStudent.
class MoveStudentButton extends ConsumerWidget {
  const MoveStudentButton({super.key, required this.summary});

  final StudentSummary summary;

  Future<void> _move(BuildContext context, WidgetRef ref) async {
    final student = summary.student;
    final targets =
        ref.read(otherHalaqatProvider(student.halaqaId)).value ?? const [];
    final halaqaId = await showChoiceDialog(
      context,
      title: AppStrings.chooseHalaqaTitle,
      choices: [for (final h in targets) (id: h.id, label: h.name)],
      emptyMessage: AppStrings.noOtherHalaqa,
    );
    if (halaqaId == null || !context.mounted) return;
    final target = targets.firstWhere((h) => h.id == halaqaId);
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.moveStudentConfirmTitle,
      message: AppStrings.moveStudentConfirm(
        student.fullName,
        summary.halaqa?.name ?? AppStrings.withoutHalaqa,
        target.name,
      ),
      confirmLabel: AppStrings.moveStudentConfirmTitle,
    );
    if (!confirmed || !context.mounted) return;
    final done = await ref
        .read(moveStudentControllerProvider(student.id).notifier)
        .move(halaqaId);
    if (done && context.mounted) {
      showAppSnackBar(context, AppStrings.studentMoved);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = moveStudentControllerProvider(summary.student.id);
    ref.listen(provider, (_, next) {
      if (next case AsyncError(:final error)) showErrorSnackBar(context, error);
    });
    // Watched so the choices are loaded by the time the button is tapped.
    ref.watch(otherHalaqatProvider(summary.student.halaqaId));
    return LoadingButton(
      filled: false,
      label: AppStrings.moveStudent,
      icon: Icons.swap_horiz,
      loading: ref.watch(provider).isLoading,
      onPressed: () => _move(context, ref),
    );
  }
}
