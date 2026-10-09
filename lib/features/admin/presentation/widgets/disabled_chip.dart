import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

/// The red-tinted "موقوف" marker of a disabled account.
class DisabledChip extends StatelessWidget {
  const DisabledChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: const Text(AppStrings.disabledChip),
      labelStyle: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: AppColors.error),
      backgroundColor: AppColors.errorTint,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
