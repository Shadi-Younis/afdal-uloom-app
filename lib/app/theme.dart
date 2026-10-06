import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Seed color for the Material 3 color scheme.
/// TODO: replace with the school's brand color.
const Color kSeedColor = Color(0xFF1B6B4A);

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: kSeedColor),
  );

  // Adjust the base styles (which carry colorScheme.onSurface) before applying
  // Cairo. Styles built from scratch with GoogleFonts.cairo() have no color,
  // which renders text white on the light background.
  final t = base.textTheme;
  final sized = t.copyWith(
    headlineMedium: t.headlineMedium!.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: t.titleLarge!.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: t.titleMedium!.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: t.bodyLarge!.copyWith(fontSize: 18),
    bodyMedium: t.bodyMedium!.copyWith(fontSize: 16),
    labelLarge: t.labelLarge!.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );

  return base.copyWith(textTheme: GoogleFonts.cairoTextTheme(sized));
}
