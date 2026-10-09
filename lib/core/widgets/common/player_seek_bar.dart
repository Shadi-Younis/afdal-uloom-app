import 'package:flutter/material.dart';

import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../utils/player_format.dart';

/// The player's progress slider, the current and total time above it.
///
/// RTL: the slider follows Material's RTL default and fills from the right
/// (the start) to the left, like the Arabic text around it. The current
/// time sits at the start (right), the total at the end (left).
class PlayerSeekBar extends StatefulWidget {
  const PlayerSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final Duration position;

  /// Null while unknown: the slider is then disabled.
  final Duration? duration;
  final ValueChanged<Duration> onSeek;

  @override
  State<PlayerSeekBar> createState() => _PlayerSeekBarState();
}

class _PlayerSeekBarState extends State<PlayerSeekBar> {
  // While the thumb is dragged it follows the finger, not the player.
  double? _dragMillis;

  @override
  Widget build(BuildContext context) {
    final total = widget.duration?.inMilliseconds ?? 0;
    final current = (_dragMillis ?? widget.position.inMilliseconds.toDouble())
        .clamp(0, total)
        .toDouble();
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatClock(Duration(milliseconds: current.round())),
                style: textStyle,
              ),
              Text(
                formatClock(widget.duration ?? Duration.zero),
                style: textStyle,
              ),
            ],
          ),
        ),
        Semantics(
          label: AppStrings.playbackPosition,
          child: Slider(
            value: current,
            max: total > 0 ? total.toDouble() : 1,
            semanticFormatterCallback: (value) =>
                formatClock(Duration(milliseconds: value.round())),
            onChanged: total > 0
                ? (value) => setState(() => _dragMillis = value)
                : null,
            onChangeEnd: total > 0
                ? (value) {
                    setState(() => _dragMillis = null);
                    widget.onSeek(Duration(milliseconds: value.round()));
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
