import 'package:flutter/material.dart';

import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../utils/player_format.dart';
import '../islamic/islamic_star.dart';
import 'player_marker.dart';

/// The lane above the seek bar: a small star at each marker's start,
/// placed from the start side like the slider fills. Tapping one calls
/// [onTap].
class PlayerMarkerLane extends StatelessWidget {
  const PlayerMarkerLane({
    super.key,
    required this.markers,
    required this.duration,
    this.onTap,
  });

  final List<PlayerMarker> markers;
  final Duration duration;
  final ValueChanged<PlayerMarker>? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: AppStrings.markersLabel,
      child: SizedBox(
        height: AppSizes.markerLane,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final marker in markers)
                  PositionedDirectional(
                    start:
                        _fraction(marker.start) * width -
                        AppSizes.markerHitWidth / 2,
                    top: 0,
                    bottom: 0,
                    width: AppSizes.markerHitWidth,
                    child: _MarkerStar(
                      marker: marker,
                      onTap: onTap == null ? null : () => onTap!(marker),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  double _fraction(Duration at) =>
      (at.inMilliseconds / duration.inMilliseconds).clamp(0, 1).toDouble();
}

class _MarkerStar extends StatelessWidget {
  const _MarkerStar({required this.marker, required this.onTap});

  final PlayerMarker marker;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppStrings.atTime(formatClock(marker.start)),
      child: InkResponse(
        onTap: onTap,
        radius: AppSizes.markerHitWidth / 2,
        child: const Center(child: IslamicStar(size: AppSizes.markerStar)),
      ),
    );
  }
}
