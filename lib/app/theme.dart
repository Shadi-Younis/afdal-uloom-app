import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The school's green: primary color and seed of the color scheme.
const Color kBrandGreen = Color(0xFF0B4019);

/// The school's gold. Decorative accents only (dividers, ornaments, icons
/// next to text): never use it for text on white, the contrast is too low.
const Color kBrandGold = Color(0xFFC59C38);

ThemeData buildAppTheme() {
  // Pure white surfaces match the white logo background, splash and app icon
  // (the seeded surface is slightly tinted).
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: kBrandGreen,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ).copyWith(
        primary: kBrandGreen,
        onPrimary: Colors.white,
        surface: Colors.white,
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.white,
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
