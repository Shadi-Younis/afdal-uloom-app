import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../constants/app_strings.dart';

/// Whether the teacher reviewed a recording: «تمت مراجعته» in green, or
/// «بانتظار المراجعة» in gold.
class ReviewedChip extends StatelessWidget {
  const ReviewedChip({super.key, required this.reviewed});

  final bool reviewed;

  @override
  Widget build(BuildContext context) {
    final color = reviewed ? AppColors.green : AppColors.goldDark;
    return Chip(
      avatar: Icon(
        reviewed ? Icons.check_circle_outline : Icons.hourglass_empty,
        color: color,
      ),
      label: Text(
        reviewed ? AppStrings.reviewedChip : AppStrings.notReviewedChip,
      ),
      labelStyle: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: color),
      backgroundColor: reviewed ? AppColors.greenTint : AppColors.goldTint,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
