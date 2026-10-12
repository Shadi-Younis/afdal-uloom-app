import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';

/// The microphone's live level, [level] 0..1, as a bar that fills from the
/// start side: green, gold when loud.
class LevelMeter extends StatelessWidget {
  const LevelMeter({super.key, required this.level});

  final double level;

  /// From here on the bar turns gold (loud).
  static const _loud = 0.85;

  @override
  Widget build(BuildContext context) {
    final value = level.clamp(0.0, 1.0);
    return Semantics(
      label: AppStrings.inputLevel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.levelMeter),
        child: Container(
          height: AppSizes.levelMeter,
          color: AppColors.track,
          alignment: AlignmentDirectional.centerStart,
          child: AnimatedFractionallySizedBox(
            duration: AppDurations.recorderTick,
            widthFactor: value,
            heightFactor: 1,
            child: ColoredBox(
              color: value >= _loud ? AppColors.gold : AppColors.green2,
            ),
          ),
        ),
      ),
    );
  }
}
