import 'package:flutter/material.dart';

import '../../constants/app_strings.dart';

/// A centered green progress indicator for content that is still loading.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(semanticsLabel: AppStrings.loading),
    );
  }
}
