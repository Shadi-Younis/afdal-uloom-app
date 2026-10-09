import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import 'section_card.dart';

/// The last section of a details page, "الحذف": [hint] (what deleting
/// does, or when it is allowed) above the destructive [button]. Kept apart
/// from the everyday actions so a delete is never tapped by mistake.
class DangerSection extends StatelessWidget {
  const DangerSection({super.key, required this.hint, required this.button});

  final String hint;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: AppStrings.dangerZone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            hint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.spaceS),
          button,
        ],
      ),
    );
  }
}
