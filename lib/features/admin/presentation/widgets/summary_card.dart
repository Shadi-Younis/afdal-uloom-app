import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';

/// A count on the admin's home ("12 الطلاب"); tapping opens its section.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.count,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final int count;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.spaceM,
            horizontal: AppSizes.spaceXS,
          ),
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: AppSizes.spaceXS),
              Text('$count', style: theme.textTheme.headlineMedium),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
