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

  final textTheme = GoogleFonts.cairoTextTheme(base.textTheme).copyWith(
    headlineMedium: GoogleFonts.cairo(
      fontSize: 28,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w600),
    bodyLarge: GoogleFonts.cairo(fontSize: 18),
    bodyMedium: GoogleFonts.cairo(fontSize: 16),
    labelLarge: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
  );

  return base.copyWith(textTheme: textTheme);
}
