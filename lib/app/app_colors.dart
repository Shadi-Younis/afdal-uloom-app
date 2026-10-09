import 'package:flutter/material.dart';

/// The app's colors (docs/design/README.md). Widgets use these or the
/// theme, never a literal color.
abstract final class AppColors {
  /// The school's green: primary color, headers, filled buttons.
  static const green = Color(0xFF0B4019);

  /// A lighter green for gradients and pressed states.
  static const green2 = Color(0xFF14572A);

  /// The school's gold. Decoration only (stars, lines, borders, icons):
  /// never text on ivory or white, the contrast is too low.
  static const gold = Color(0xFFC59C38);

  /// Hairline borders of cards, fields and buttons; text on green.
  static const goldLight = Color(0xFFE6D3A0);

  /// Gold for TEXT on light backgrounds (the hadith, chip labels).
  static const goldDark = Color(0xFF8A6A1E);

  /// The page background.
  static const ivory = Color(0xFFFBF8F1);

  /// Cards, fields, dialogs and the navigation bar.
  static const card = Color(0xFFFFFFFF);

  /// Body text.
  static const ink = Color(0xFF1E2A22);

  /// Secondary text: labels, dates, hints.
  static const muted = Color(0xFF6B756D);

  /// Errors; readable on ivory and white.
  static const error = Color(0xFFB3261E);

  // Tints from the mockup, derived from the colors above.

  /// The selected item's pill in the navigation bar, and card shadows.
  static const greenTint = Color(0x1A0B4019);

  /// Chips such as the recording type and "عند ٠١:٠٥".
  static const goldTint = Color(0x22C59C38);

  /// The halo around the player's play button.
  static const goldHalo = Color(0x44C59C38);

  /// The empty part of the player's progress bar.
  static const track = Color(0xFFEEE7D6);

  /// The disabled-account chip.
  static const errorTint = Color(0x1FB3261E);

  /// White on top of green.
  static const onGreen = Color(0xFFFFFFFF);
}
