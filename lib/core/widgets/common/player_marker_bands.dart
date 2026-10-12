import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../constants/app_sizes.dart';
import 'player_marker.dart';

/// Under the seek bar's track: a subtle gold band over each span where the
/// sheikh spoke (markers with an end), placed from the start side like the
/// slider fills. Purely visual.
class PlayerMarkerBands extends StatelessWidget {
  const PlayerMarkerBands({
    super.key,
    required this.markers,
    required this.duration,
  });

  final List<PlayerMarker> markers;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final top = (constraints.maxHeight - AppSizes.markerBand) / 2;
          return Stack(
            children: [
              for (final marker in markers)
                if (marker.end case final end?)
                  PositionedDirectional(
                    start: _fraction(marker.start) * width,
                    top: top,
                    height: AppSizes.markerBand,
                    width: ((_fraction(end) - _fraction(marker.start)) * width)
                        .clamp(AppSizes.hairline * 2, width)
                        .toDouble(),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.goldHalo,
                        borderRadius: BorderRadius.all(
                          Radius.circular(AppSizes.markerBand / 2),
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  double _fraction(Duration at) =>
      (at.inMilliseconds / duration.inMilliseconds).clamp(0, 1).toDouble();
}
