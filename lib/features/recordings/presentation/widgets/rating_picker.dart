import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/model_limits.dart';
import '../../../../core/utils/arabic_digits.dart';

/// An optional rating: [ModelLimits.ratingMax] stars to tap, and «بلا
/// تقييم» to leave it empty. [rating] null: no star filled.
class RatingPicker extends StatelessWidget {
  const RatingPicker({
    super.key,
    required this.rating,
    required this.onChanged,
    this.enabled = true,
  });

  final int? rating;
  final ValueChanged<int?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = rating ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.ratingOptional,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = ModelLimits.ratingMin; i <= ModelLimits.ratingMax; i++)
              IconButton(
                tooltip: AppStrings.rateStars(toArabicDigits(i)),
                onPressed: enabled ? () => onChanged(i) : null,
                icon: Icon(
                  i <= current ? Icons.star : Icons.star_border,
                  // Gold is fine for icons; only text on white must avoid it.
                  color: AppColors.gold,
                ),
              ),
            TextButton(
              onPressed: enabled && rating != null
                  ? () => onChanged(null)
                  : null,
              child: const Text(AppStrings.clearRating),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spaceXS),
      ],
    );
  }
}
