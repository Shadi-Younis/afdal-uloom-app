import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';

/// One "label: value" line of a details page. [ltr] for usernames and
/// codes, which read left to right inside the Arabic layout.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.ltr = false,
    this.trailing,
  });

  final String label;
  final String value;
  final bool ltr;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceXS),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSizes.spaceS),
          Expanded(
            child: Text(
              value,
              textDirection: ltr ? TextDirection.ltr : null,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
