import 'package:afdal_uloom_tilawat/app/app_colors.dart';
import 'package:afdal_uloom_tilawat/app/app_text_styles.dart';
import 'package:afdal_uloom_tilawat/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  // Plain test() does not set up the binding google_fonts needs for assets.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Same as main(): fonts must come from assets/google_fonts/.
    GoogleFonts.config.allowRuntimeFetching = false;
    buildAppTheme();
    await GoogleFonts.pendingFonts();
  });

  // Regression: styles built from scratch with GoogleFonts.cairo() had no
  // color, so theme text rendered white on the light background.
  // Weight null = not overridden by the theme (body styles only set size).
  final expected = <String, (double, FontWeight?)>{
    'headlineMedium': (28, FontWeight.w700),
    'titleLarge': (22, FontWeight.w600),
    'titleMedium': (18, FontWeight.w600),
    'bodyLarge': (18, null),
    'bodyMedium': (16, null),
    'labelLarge': (16, FontWeight.w700),
  };

  TextStyle? styleOf(TextTheme textTheme, String name) => switch (name) {
    'headlineMedium' => textTheme.headlineMedium,
    'titleLarge' => textTheme.titleLarge,
    'titleMedium' => textTheme.titleMedium,
    'bodyLarge' => textTheme.bodyLarge,
    'bodyMedium' => textTheme.bodyMedium,
    'labelLarge' => textTheme.labelLarge,
    _ => throw ArgumentError(name),
  };

  test('primary is the school green with white on top', () {
    final scheme = buildAppTheme().colorScheme;

    expect(scheme.primary, const Color(0xFF0B4019));
    expect(scheme.onPrimary, const Color(0xFFFFFFFF));
  });

  test('pages are ivory, cards and surfaces white, text ink', () {
    final theme = buildAppTheme();

    expect(theme.scaffoldBackgroundColor, const Color(0xFFFBF8F1));
    expect(theme.colorScheme.surface, const Color(0xFFFFFFFF));
    expect(theme.colorScheme.onSurface, AppColors.ink);
  });

  test('cards: white, radius 16, gold hairline', () {
    final shape = buildAppTheme().cardTheme.shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(16));
    expect(shape.side.color, AppColors.goldLight);
  });

  test('named styles: Amiri for Quranic text, Reem Kufi for headings', () {
    final styles = buildAppTheme().extension<AppTextStyles>()!;
    for (final style in [styles.basmala, styles.hadith, styles.surahTitle]) {
      expect(style.fontFamily, contains('Amiri'));
    }
    for (final style in [
      styles.heading,
      styles.sectionTitle,
      styles.statNumber,
      styles.headerName,
    ]) {
      expect(style.fontFamily, contains('ReemKufi'));
      expect(style.fontWeight, FontWeight.w600);
    }
    expect(styles.hadith.color, AppColors.goldDark);
    expect(styles.basmala.color, AppColors.green);
  });

  for (final MapEntry(key: name, value: (size, weight)) in expected.entries) {
    test('$name keeps onSurface color and uses Cairo', () {
      final theme = buildAppTheme();
      final style = styleOf(theme.textTheme, name)!;

      expect(style.color, isNotNull);
      expect(style.color, theme.colorScheme.onSurface);
      expect(style.fontFamily, contains('Cairo'));
      expect(style.fontSize, size);
      if (weight != null) expect(style.fontWeight, weight);
    });
  }
}
