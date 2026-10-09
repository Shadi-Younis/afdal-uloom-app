import 'package:flutter/material.dart';

import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';

/// A button that runs a server call: disabled while [loading], with a
/// progress indicator in place of its icon. [filled] picks a FilledButton
/// (the main action) over an OutlinedButton.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.icon,
    this.filled = true,
  });

  final String label;
  final bool loading;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;

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
    if (filled) {
      return leading == null
          ? FilledButton(onPressed: onTap, child: text)
          : FilledButton.icon(onPressed: onTap, icon: leading, label: text);
    }
    return leading == null
        ? OutlinedButton(onPressed: onTap, child: text)
        : OutlinedButton.icon(onPressed: onTap, icon: leading, label: text);
  }
}
