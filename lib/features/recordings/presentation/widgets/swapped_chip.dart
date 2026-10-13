import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';

/// «تم تبديل الطالب والشيخ تلقائياً»: the server found the sheikh on the
/// left channel and swapped them before placing the markers. For the
/// recording's teacher only; the student hears one centred recording.
class SwappedChip extends StatelessWidget {
  const SwappedChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceS),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Chip(
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: AppColors.goldTint,
          side: BorderSide.none,
          avatar: const Icon(
            Icons.swap_horiz,
            size: AppSizes.chipIcon,
            color: AppColors.goldDark,
          ),
          label: const Text(AppStrings.swappedChip),
          labelStyle: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: AppColors.goldDark),
        ),
      ),
    );
  }
}
