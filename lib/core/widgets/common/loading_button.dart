import 'package:flutter/material.dart';

import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';

/// A button that runs a server call: disabled while [loading], with a
/// progress indicator in place of its icon. [filled] picks a FilledButton
/// (the main action) over an OutlinedButton; [destructive] draws it in the
/// error color, for actions that delete.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.icon,
    this.filled = true,
    this.destructive = false,
  });

  final String label;
  final bool loading;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final onTap = loading ? null : onPressed;
    final leading = loading
        ? const SizedBox.square(
            dimension: AppSizes.buttonProgressSize,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.progressStrokeWidth,
              semanticsLabel: AppStrings.loading,
            ),
          )
        : icon == null
        ? null
        : Icon(icon);
    final text = Text(label);
    final colors = Theme.of(context).colorScheme;
    if (filled) {
      final style = destructive
          ? FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            )
          : null;
      return leading == null
          ? FilledButton(onPressed: onTap, style: style, child: text)
          : FilledButton.icon(
              onPressed: onTap,
              style: style,
              icon: leading,
              label: text,
            );
    }
    final style = destructive
        ? OutlinedButton.styleFrom(
            foregroundColor: colors.error,
            side: BorderSide(color: colors.error),
          )
        : null;
    return leading == null
        ? OutlinedButton(onPressed: onTap, style: style, child: text)
        : OutlinedButton.icon(
            onPressed: onTap,
            style: style,
            icon: leading,
            label: text,
          );
  }
}
