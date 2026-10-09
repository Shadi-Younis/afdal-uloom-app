import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/common/school_logo.dart';
import '../../../core/widgets/islamic/islamic_pattern_background.dart';
import '../../../core/widgets/islamic/loading_state.dart';

/// Shown while the session is still unknown at start-up, so a signed-in
/// user never sees the login screen flash by. Ivory like the native splash
/// before it, so the switch is seamless.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: IslamicPatternBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SchoolLogo(size: AppSizes.logoMedium),
              SizedBox(height: AppSizes.spaceL),
              LoadingState(),
            ],
          ),
        ),
      ),
    );
  }
}
