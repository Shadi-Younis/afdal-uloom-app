import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/islamic/app_card.dart';
import '../../application/analysis_notice.dart';

/// What the server's analysis of the recording says: still running, no
/// sheikh channel in the file, or failed (notes can still be added by
/// hand).
class AnalysisBanner extends StatelessWidget {
  const AnalysisBanner({super.key, required this.notice});

  final AnalysisNotice notice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, text) = switch (notice) {
      AnalysisNotice.pending => (null, AppStrings.analysisPending),
      AnalysisNotice.mono => (Icons.info_outline, AppStrings.analysisMono),
      AnalysisNotice.failed => (Icons.error_outline, AppStrings.analysisFailed),
    };
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSizes.spaceS),
      child: Row(
        children: [
          if (icon == null)
            const SizedBox.square(
              dimension: AppSizes.buttonProgressSize,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.progressStrokeWidth,
              ),
            )
          else
            Icon(icon, color: AppColors.goldDark),
          const SizedBox(width: AppSizes.spaceS),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
