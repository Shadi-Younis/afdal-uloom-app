import 'package:flutter/material.dart';

import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../constants/playback_speeds.dart';
import '../../utils/player_format.dart';

/// Picks one of [PlaybackSpeeds.all].
class PlaybackSpeedSelector extends StatelessWidget {
  const PlaybackSpeedSelector({
    super.key,
    required this.speed,
    required this.onChanged,
  });

  final double speed;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.playbackSpeed,
      child: SegmentedButton<double>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(AppSizes.touchTarget, AppSizes.touchTarget),
        ),
        segments: [
          for (final value in PlaybackSpeeds.all)
            ButtonSegment(value: value, label: Text(formatSpeed(value))),
        ],
        selected: {speed},
        onSelectionChanged: (selected) => onChanged(selected.single),
      ),
    );
  }
}
