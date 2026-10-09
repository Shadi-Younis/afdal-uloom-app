import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../constants/app_durations.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../utils/arabic_digits.dart';

/// Back 5 s, play / pause, forward 5 s. In RTL "back" is at the start
/// (right) and "forward" at the end (left), the direction the seek bar
/// fills in.
class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.playing,
    required this.buffering,
    required this.onTogglePlay,
    required this.onSkipBack,
    required this.onSkipForward,
  });

  final bool playing;

  /// Shows a progress ring around the play button.
  final bool buffering;
  final VoidCallback onTogglePlay;
  final VoidCallback onSkipBack;
  final VoidCallback onSkipForward;

  @override
  Widget build(BuildContext context) {
    final seconds = toArabicDigits(AppDurations.playerSkip.inSeconds);
    const minSize = BoxConstraints(
      minWidth: AppSizes.touchTarget,
      minHeight: AppSizes.touchTarget,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: AppStrings.skipBack(seconds),
          constraints: minSize,
          iconSize: AppSizes.skipIcon,
          onPressed: onSkipBack,
          icon: const Icon(Icons.replay_5),
        ),
        const SizedBox(width: AppSizes.spaceL),
        Container(
          width: AppSizes.playButton,
          height: AppSizes.playButton,
          // The gold halo of the design.
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.goldHalo,
                spreadRadius: AppSizes.playHalo,
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              IconButton.filled(
                tooltip: playing ? AppStrings.pause : AppStrings.play,
                iconSize: AppSizes.playIcon,
                onPressed: onTogglePlay,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              ),
              if (buffering)
                const IgnorePointer(child: CircularProgressIndicator()),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.spaceL),
        IconButton(
          tooltip: AppStrings.skipForward(seconds),
          constraints: minSize,
          iconSize: AppSizes.skipIcon,
          onPressed: onSkipForward,
          icon: const Icon(Icons.forward_5),
        ),
      ],
    );
  }
}
