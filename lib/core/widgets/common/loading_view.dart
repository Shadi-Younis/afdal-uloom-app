import 'package:flutter/material.dart';

import '../../constants/app_strings.dart';

/// A centered progress indicator for content that is still loading.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(semanticsLabel: AppStrings.loading),
    );
  }
}
