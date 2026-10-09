import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_strings.dart';

/// Opens "حسابي" (the signed-in user's own account) on top of the current
/// page. [onGreen] draws it as the round white-outlined button of the
/// green home header, next to sign-out.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key, this.onGreen = false});

  final bool onGreen;

  static const _circle = 36.0;
  static const _ringAlpha = 0.25;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: onGreen
          ? Container(
              width: _circle,
              height: _circle,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.onGreen.withValues(alpha: _ringAlpha),
                ),
              ),
              child: const Icon(Icons.person_outline, color: AppColors.onGreen),
            )
          : const Icon(Icons.person_outline, color: AppColors.green),
      tooltip: AppStrings.myAccount,
      onPressed: () => context.push(AppRoutes.account),
    );
  }
}
