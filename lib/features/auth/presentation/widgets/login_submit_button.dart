import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';

/// Full-width "دخول" button that shows a progress indicator while loading.
class LoginSubmitButton extends StatelessWidget {
  const LoginSubmitButton({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? SizedBox.square(
                dimension: AppSizes.buttonProgressSize,
                child: CircularProgressIndicator(
                  strokeWidth: AppSizes.progressStrokeWidth,
                  color: Theme.of(context).colorScheme.primary,
                  semanticsLabel: AppStrings.loading,
                ),
              )
            : const Text(AppStrings.signIn),
      ),
    );
  }
}
