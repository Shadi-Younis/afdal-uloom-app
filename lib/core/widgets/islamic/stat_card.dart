import 'package:flutter/material.dart';

import '../../../app/app_text_styles.dart';
import '../../constants/app_sizes.dart';
import '../../utils/arabic_digits.dart';
import 'app_card.dart';
import 'islamic_star.dart';

/// A count on a home screen: the star, the number (Reem Kufi,
/// Arabic-Indic digits) and its label. Tapping opens its section.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.number,
    required this.label,
    this.onTap,
  });

  final int number;
  final String label;
  final VoidCallback? onTap;

  static const starSize = 40.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.spaceS,
        horizontal: AppSizes.spaceXS,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const IslamicStar(size: starSize),
          const SizedBox(height: AppSizes.spaceXS),
          Text(
            toArabicDigits(number),
            style: AppTextStyles.of(context).statNumber,
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
