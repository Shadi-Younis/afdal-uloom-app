import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';

/// «يُحفظ التدريب عندك فقط» under «حفظ»: a practice is the student's own;
/// the sheikh and the admins never see it.
class PracticePrivateNote extends StatelessWidget {
  const PracticePrivateNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.spaceXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: AppSizes.chipIcon,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSizes.spaceXS),
          Flexible(
            child: Text(
              AppStrings.practicePrivate,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
