import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../models/recording_type.dart';

/// "رسمي" (studio) or "تدريب" (practice), on a gold tint.
class RecordingTypeChip extends StatelessWidget {
  const RecordingTypeChip({super.key, required this.type});

  final RecordingType type;

  @override
  Widget build(BuildContext context) {
    final official = type == RecordingType.official;
    return Chip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: AppColors.goldTint,
      side: BorderSide.none,
      avatar: Icon(
        official ? Icons.verified_outlined : Icons.mic_none,
        size: AppSizes.chipIcon,
        color: AppColors.goldDark,
      ),
      label: Text(official ? AppStrings.typeOfficial : AppStrings.typePractice),
      labelStyle: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: AppColors.goldDark),
    );
  }
}
