import 'package:flutter/material.dart';

import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../models/recording_type.dart';

/// "رسمي" (studio) or "تدريب" (practice).
class RecordingTypeChip extends StatelessWidget {
  const RecordingTypeChip({super.key, required this.type});

  final RecordingType type;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final official = type == RecordingType.official;
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(
        official ? Icons.verified_outlined : Icons.mic_none,
        size: AppSizes.chipIcon,
        color: official ? colors.primary : colors.onSurfaceVariant,
      ),
      label: Text(official ? AppStrings.typeOfficial : AppStrings.typePractice),
    );
  }
}
