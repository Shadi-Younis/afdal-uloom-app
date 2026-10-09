import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_colors.dart';
import '../../constants/app_sizes.dart';
import 'islamic_pattern_background.dart';

/// The green header of the home screens: the geometric pattern, rounded
/// bottom corners and a gold line near the bottom. [top] is the first row
/// (e.g. Hijri date and an action), [child] the content under it (e.g.
/// greeting and name). Extends behind the status bar.
class OrnateHeader extends StatelessWidget {
  const OrnateHeader({super.key, required this.top, required this.child});

  final Widget top;
  final Widget child;

  /// Room left under the content, which the stat cards overlap.
  static const bottomPadding = 34.0;
  static const _goldLineBottom = 10.0;
  static const _goldLineHeight = 2.0;

  @override
  Widget build(BuildContext context) {
    // Light status bar icons on the green.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppSizes.radiusHeader),
        ),
        child: ColoredBox(
          color: AppColors.green,
          child: IslamicPatternBackground(
            opacity: IslamicPatternBackground.onGreen,
            child: Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSizes.spaceL,
                      AppSizes.spaceL,
                      AppSizes.spaceL,
                      bottomPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [top, child],
                    ),
                  ),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: _goldLineBottom,
                  height: _goldLineHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.gold,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
