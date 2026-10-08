import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common/school_logo.dart';
import 'widgets/login_form.dart';

/// Username + password sign-in. There is no sign-up: accounts are created
/// by the school.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          // Scrolls instead of overflowing on short screens, large text or
          // with the keyboard open.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SchoolLogo(size: AppSizes.logoLarge),
                const SizedBox(height: AppSizes.spaceL),
                Text(
                  AppStrings.loginTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSizes.spaceXL),
                const LoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
