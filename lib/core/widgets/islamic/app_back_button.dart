import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';

/// The round white back button with a gold hairline (48 dp touch target).
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static const _circle = 36.0;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppStrings.back,
      onPressed: onPressed,
      constraints: const BoxConstraints(
        minWidth: AppSizes.touchTarget,
        minHeight: AppSizes.touchTarget,
      ),
      icon: Container(
        width: _circle,
        height: _circle,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.goldLight,
            width: AppSizes.hairline,
          ),
        ),
        // arrow_back follows the text direction: it points right in RTL.
        child: const Icon(Icons.arrow_back, color: AppColors.green),
      ),
    );
  }
}
