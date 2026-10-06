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
    'labelLarge': (16, FontWeight.w600),
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
