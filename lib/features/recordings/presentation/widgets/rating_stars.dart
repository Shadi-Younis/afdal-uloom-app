import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/model_limits.dart';
import '../../../../core/utils/arabic_digits.dart';

/// A teacher's rating as [ModelLimits.ratingMax] stars, [rating] filled.
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: AppStrings.ratingOf(
        toArabicDigits(rating),
        toArabicDigits(ModelLimits.ratingMax),
      ),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= ModelLimits.ratingMax; i++)
              Icon(
                i <= rating ? Icons.star : Icons.star_border,
                // Gold is fine for icons; only text on white must avoid it.
                color: kBrandGold,
                size: AppSizes.ratingStar,
              ),
          ],
        ),
      ),
    );
  }
}
