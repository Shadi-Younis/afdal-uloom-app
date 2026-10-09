import 'dart:math';

import 'package:afdal_uloom_tilawat/app/app_colors.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 contrast ratio of two opaque colors.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  test('the exact colors of the design', () {
    expect(AppColors.green, const Color(0xFF0B4019));
    expect(AppColors.green2, const Color(0xFF14572A));
    expect(AppColors.gold, const Color(0xFFC59C38));
    expect(AppColors.goldLight, const Color(0xFFE6D3A0));
    expect(AppColors.goldDark, const Color(0xFF8A6A1E));
    expect(AppColors.ivory, const Color(0xFFFBF8F1));
    expect(AppColors.card, const Color(0xFFFFFFFF));
    expect(AppColors.ink, const Color(0xFF1E2A22));
    expect(AppColors.muted, const Color(0xFF6B756D));
  });

  // Text must reach 4.5:1 (WCAG AA for body text) on its background.
  const pairs = {
    'ink on ivory': (AppColors.ink, AppColors.ivory),
    'muted on ivory': (AppColors.muted, AppColors.ivory),
    'muted on white': (AppColors.muted, AppColors.card),
    'goldDark on ivory': (AppColors.goldDark, AppColors.ivory),
    'white on green': (AppColors.onGreen, AppColors.green),
    'goldLight on green': (AppColors.goldLight, AppColors.green),
    'green on ivory': (AppColors.green, AppColors.ivory),
    'error on ivory': (AppColors.error, AppColors.ivory),
  };
  for (final MapEntry(key: name, value: (fg, bg)) in pairs.entries) {
    test('$name is readable (>= 4.5:1)', () {
      expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
    });
  }

  test('gold itself is NOT readable as text on ivory: decoration only', () {
    expect(contrast(AppColors.gold, AppColors.ivory), lessThan(4.5));
  });
}
