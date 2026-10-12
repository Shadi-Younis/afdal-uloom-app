import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/widgets/common/disabled_chip.dart';
import '../../application/teacher_providers.dart';

/// The student's name, code and halaqa, and «موقوف» when disabled.
class TeacherStudentInfo extends ConsumerWidget {
  const TeacherStudentInfo({
    super.key,
    required this.student,
    required this.halaqaId,
  });

  final AppUser student;
  final String halaqaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final halaqa = ref.watch(teacherHalaqaProvider(halaqaId)).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoLine(label: AppStrings.nameLabel, value: student.fullName),
        _InfoLine(
          label: AppStrings.studentCodeLabel,
          value: student.studentCode ?? '',
        ),
        _InfoLine(label: AppStrings.halaqaLabel, value: halaqa?.name ?? ''),
        if (student.disabled)
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: DisabledChip(),
          ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceXS),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
