import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';

/// The school's round logo, [size] logical pixels wide and high.
class SchoolLogo extends StatelessWidget {
  const SchoolLogo({super.key, this.size = AppSizes.logoLarge});

  static const semanticLabel = AppStrings.schoolLogoLabel;

  final double size;

  @override
  Widget build(BuildContext context) {
    // Decode at the size it is drawn (never above the 600px source) instead
    // of keeping the full image in memory.
    final cacheWidth = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return Image.asset(
      AppAssets.logo,
      width: size,
      height: size,
      cacheWidth: cacheWidth,
      semanticLabel: semanticLabel,
    );
  }
}
