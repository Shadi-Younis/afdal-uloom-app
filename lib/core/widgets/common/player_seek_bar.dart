import 'package:flutter/material.dart';

import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../utils/player_format.dart';
import 'player_marker.dart';
import 'player_marker_bands.dart';
import 'player_marker_lane.dart';

/// The player's progress slider, the current and total time above it, and
/// the [markers] (a teacher's notes, the sheikh's voice markers): a gold
/// star each in a lane above the slider, and a gold band under the track
/// for a voice marker's span. Tapping a star calls [onMarkerTap].
///
/// RTL: the slider follows Material's RTL default and fills from the right
/// (the start) to the left, like the Arabic text around it. The current
/// time sits at the start (right), the total at the end (left); markers are
/// placed from the start too.
class PlayerSeekBar extends StatefulWidget {
  const PlayerSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.markers = const [],
    this.onMarkerTap,
  });

  final Duration position;

  /// Null while unknown: the slider is then disabled and no marker shows.
  final Duration? duration;
  final ValueChanged<Duration> onSeek;
  final List<PlayerMarker> markers;
  final ValueChanged<PlayerMarker>? onMarkerTap;

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
    final markers = total > 0 ? widget.markers : const <PlayerMarker>[];
    final slider = Semantics(
      label: AppStrings.playbackPosition,
      child: SliderTheme(
        // No inner padding: the track spans the whole width, so the
        // markers above and under it line up with it exactly.
        data: SliderTheme.of(context).copyWith(padding: EdgeInsets.zero),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceM),
          child: Column(
            children: [
              if (markers.isNotEmpty)
                PlayerMarkerLane(
                  markers: markers,
                  duration: widget.duration!,
                  onTap: widget.onMarkerTap,
                ),
              SizedBox(
                height: AppSizes.touchTarget,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (markers.isNotEmpty)
                      Positioned.fill(
                        child: PlayerMarkerBands(
                          markers: markers,
                          duration: widget.duration!,
                        ),
                      ),
                    slider,
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
