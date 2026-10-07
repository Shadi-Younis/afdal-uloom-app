import 'package:flutter/material.dart';

/// The school's round logo, [size] logical pixels wide and high.
class SchoolLogo extends StatelessWidget {
  const SchoolLogo({super.key, this.size = 160});

  static const semanticLabel = 'شعار دار أفضل العلوم';

  final double size;

  @override
  Widget build(BuildContext context) {
    // Decode at the size it is drawn (never above the 600px source) instead
    // of keeping the full image in memory.
    final cacheWidth = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return Image.asset(
      'assets/branding/logo_600.png',
      width: size,
      height: size,
      cacheWidth: cacheWidth,
      semanticLabel: semanticLabel,
    );
  }
}
