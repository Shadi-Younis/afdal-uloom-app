import 'package:flutter/material.dart';

import '../../../app/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common/school_logo.dart';
import '../../../core/widgets/islamic/islamic_pattern_background.dart';
import '../../../core/widgets/islamic/ornament_divider.dart';
import 'widgets/login_form.dart';

/// Username + password sign-in, under the basmala, the logo and the hadith
/// «خيركم من تعلّم القرآن وعلّمه». There is no sign-up: accounts are
/// created by the school.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final styles = AppTextStyles.of(context);
    return Scaffold(
      body: IslamicPatternBackground(
        child: SafeArea(
          child: Center(
            // Scrolls instead of overflowing on short screens, large text
            // or with the keyboard open.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.contentMaxWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.basmala,
                      textAlign: TextAlign.center,
                      style: styles.basmala,
                    ),
                    const SizedBox(height: AppSizes.spaceM),
                    const Center(child: SchoolLogo(size: AppSizes.logoLarge)),
                    const SizedBox(height: AppSizes.spaceXS),
                    Text(
                      AppStrings.hadith,
                      textAlign: TextAlign.center,
                      style: styles.hadith,
                    ),
                    const SizedBox(height: AppSizes.spaceS),
                    const OrnamentDivider(title: AppStrings.loginTitle),
                    const SizedBox(height: AppSizes.spaceS),
                    const LoginForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
