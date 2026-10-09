import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common/app_snack_bar.dart';
import '../../../../core/widgets/common/confirm_dialog.dart';
import '../../../../core/widgets/common/loading_button.dart';
import '../../application/admin_data_providers.dart';
import '../../application/change_halaqa_teacher_controller.dart';
import '../../application/halaqa_summary.dart';
import 'choice_dialog.dart';

/// "تغيير المعلم": pick an active teacher, confirm (the halaqa's recordings
/// move to them), then changeHalaqaTeacher.
class ChangeTeacherButton extends ConsumerWidget {
  const ChangeTeacherButton({super.key, required this.summary});

  final HalaqaSummary summary;

  Future<void> _change(BuildContext context, WidgetRef ref) async {
    final halaqa = summary.halaqa;
    final targets =
        ref.read(otherActiveTeachersProvider(halaqa.teacherId)).value ??
        const [];
    final teacherId = await showChoiceDialog(
      context,
      title: AppStrings.chooseTeacherTitle,
      choices: [for (final t in targets) (id: t.id, label: t.fullName)],
      emptyMessage: AppStrings.noOtherTeacher,
    );
    if (teacherId == null || !context.mounted) return;
    final target = targets.firstWhere((t) => t.id == teacherId);
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.changeTeacherConfirmTitle,
      message: AppStrings.changeTeacherConfirm(
        halaqa.name,
        summary.teacher?.fullName ?? AppStrings.unknownTeacher,
        target.fullName,
      ),
      confirmLabel: AppStrings.changeTeacher,
    );
    if (!confirmed || !context.mounted) return;
    final done = await ref
        .read(changeHalaqaTeacherControllerProvider(halaqa.id).notifier)
        .change(teacherId);
    if (done && context.mounted) {
      showAppSnackBar(context, AppStrings.teacherChanged);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = changeHalaqaTeacherControllerProvider(summary.halaqa.id);
    ref.listen(provider, (_, next) {
      if (next case AsyncError(:final error)) showErrorSnackBar(context, error);
    });
    // Watched so the choices are loaded by the time the button is tapped.
    ref.watch(otherActiveTeachersProvider(summary.halaqa.teacherId));
    return LoadingButton(
      filled: false,
      label: AppStrings.changeTeacher,
      icon: Icons.person_search_outlined,
      loading: ref.watch(provider).isLoading,
      onPressed: () => _change(context, ref),
    );
  }
}
