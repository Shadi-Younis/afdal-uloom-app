import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

/// The recorder's big round green button with the gold halo of the design
/// (as the player's play button). [busy] shows a spinner over it and
/// disables it.
class RecordButton extends StatelessWidget {
  const RecordButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.busy = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.recordButton,
      height: AppSizes.recordButton,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.goldHalo,
            spreadRadius: AppSizes.recordHalo,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IconButton.filled(
            tooltip: tooltip,
            iconSize: AppSizes.recordIcon,
            onPressed: busy ? null : onPressed,
            icon: Icon(icon),
          ),
          if (busy) const IgnorePointer(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
