import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../models/daily_hadith.dart';
import 'app_card.dart';
import 'islamic_star.dart';

/// «حديث اليوم» on a home: the title between two small stars, «قال رسول
/// الله ﷺ:», then [hadith] centred in Amiri between gold « » (never the
/// Quranic ﴿ ﴾), and its source, small and muted, when it has one.
class DailyHadithCard extends StatelessWidget {
  const DailyHadithCard({super.key, required this.hadith});

  final DailyHadith hadith;

  static const starSize = 16.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final styles = AppTextStyles.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final quote = styles.dailyHadith.copyWith(color: AppColors.goldDark);
    final source = hadith.source;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const IslamicStar(size: starSize),
              const SizedBox(width: AppSizes.spaceS),
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(
                    AppStrings.dailyHadithTitle,
                    textAlign: TextAlign.center,
                    style: styles.sectionTitle,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spaceS),
              const IslamicStar(size: starSize),
            ],
          ),
          const SizedBox(height: AppSizes.spaceXS),
          // Amiri too: Cairo draws ﷺ small and cramped.
          Text(
            AppStrings.prophetSaid,
            textAlign: TextAlign.center,
            style: styles.dailyHadith.copyWith(
              fontSize: muted?.fontSize,
              fontWeight: FontWeight.w400,
              color: muted?.color,
              height: 1.5,
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: AppStrings.quoteOpen, style: quote),
                TextSpan(text: hadith.text),
                TextSpan(text: AppStrings.quoteClose, style: quote),
              ],
            ),
            textAlign: TextAlign.center,
            style: styles.dailyHadith,
          ),
          if (source != null)
            Text(
              source,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
