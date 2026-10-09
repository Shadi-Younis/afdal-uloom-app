import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../constants/app_sizes.dart';
import 'islamic_star.dart';

/// A section title between ornaments: line · star · [title] · star · line,
/// the gold lines fading out toward the edges.
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key, required this.title});

  final String title;

  static const starSize = 22.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceS),
      child: Row(
        children: [
          const Expanded(child: _FadingLine(fromStart: true)),
          const SizedBox(width: AppSizes.spaceS),
          const IslamicStar(size: starSize),
          const SizedBox(width: AppSizes.spaceS),
          Flexible(
            flex: 0,
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.of(context).sectionTitle,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spaceS),
          const IslamicStar(size: starSize),
          const SizedBox(width: AppSizes.spaceS),
          const Expanded(child: _FadingLine(fromStart: false)),
        ],
      ),
    );
  }
}

/// A gold hairline, transparent at the outer edge.
class _FadingLine extends StatelessWidget {
  const _FadingLine({required this.fromStart});

  /// The line on the start side (it fades toward the start).
  final bool fromStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.hairline,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: fromStart
              ? const [Colors.transparent, AppColors.gold]
              : const [AppColors.gold, Colors.transparent],
        ),
      ),
    );
  }
}
