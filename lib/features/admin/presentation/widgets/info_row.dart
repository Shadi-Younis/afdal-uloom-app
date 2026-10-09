import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';

/// One "label: value" line of a details page: the label at the start, the
/// value at the end. [ltr] for usernames, codes and passwords, which read
/// left to right inside the Arabic layout. [valueWidget], when given, is
/// shown instead of [value] (e.g. a status chip).
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    this.value = '',
    this.ltr = false,
    this.valueWidget,
  });

  final String label;
  final String value;
  final bool ltr;
  final Widget? valueWidget;

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
            // Aligned by the layout, not by textAlign: an LTR text's "end"
            // is its right, which in this RTL row is next to the label.
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child:
                  valueWidget ??
                  Text(
                    value,
                    textDirection: ltr ? TextDirection.ltr : null,
                    style: theme.textTheme.bodyLarge,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
