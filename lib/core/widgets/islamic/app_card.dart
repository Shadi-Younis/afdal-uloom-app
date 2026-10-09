import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../constants/app_sizes.dart';

/// The app's card: white, radius 16, a gold hairline and a soft green
/// shadow. [onTap] makes it tappable (with ripple). [accent] adds a gold
/// bar on the start side, as on a teacher's note.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSizes.spaceM),
    this.margin = EdgeInsets.zero,
    this.accent = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final bool accent;

  static const accentWidth = 4.0;

  static const shadow = BoxShadow(
    color: AppColors.greenTint,
    blurRadius: AppSizes.cardShadowBlur,
    offset: Offset(0, AppSizes.cardShadowOffset),
  );

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(AppSizes.radiusCard));
    Widget content = Padding(
      padding: accent
          ? padding.add(const EdgeInsetsDirectional.only(start: accentWidth))
          : padding,
      child: child,
    );
    if (onTap != null) content = InkWell(onTap: onTap, child: content);
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: radius,
          border: Border.all(
            color: AppColors.goldLight,
            width: AppSizes.hairline,
          ),
          boxShadow: const [shadow],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            type: MaterialType.transparency,
            // passthrough: the content gets the card's width, so centered
            // content is centered in the card.
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                content,
                if (accent)
                  const PositionedDirectional(
                    start: 0,
                    top: 0,
                    bottom: 0,
                    width: accentWidth,
                    child: ColoredBox(color: AppColors.gold),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
