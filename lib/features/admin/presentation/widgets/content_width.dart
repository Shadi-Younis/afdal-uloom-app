import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';

/// Keeps forms and details pages readable on the wide studio screen: at
/// most [AppSizes.contentMaxWidth] wide, centered. No effect on a phone.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: child,
      ),
    );
  }
}
