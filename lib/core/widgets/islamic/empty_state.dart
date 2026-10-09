import 'package:flutter/material.dart';

import '../../constants/app_sizes.dart';
import 'islamic_star.dart';

/// "Nothing here yet": a large faded star, [message], and a button when
/// [actionLabel] and [onAction] are given. Centered; scrolls on short
/// screens.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  static const starSize = 72.0;
  static const starOpacity = 0.25;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Opacity(
              opacity: starOpacity,
              child: IslamicStar(size: starSize),
            ),
            const SizedBox(height: AppSizes.spaceM),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSizes.spaceL),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
