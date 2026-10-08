/// Spacing, paddings, radii and icon / logo sizes, in logical pixels.
abstract final class AppSizes {
  // Spacing scale, used for paddings and gaps.
  static const spaceS = 12.0;
  static const spaceL = 24.0;
  static const spaceXL = 32.0;

  /// Outer padding of full-screen forms such as login.
  static const screenPadding = spaceL;

  /// The school logo on the login screen.
  static const logoLarge = 160.0;

  /// The school logo on the start-up screen.
  static const logoMedium = 120.0;

  /// Height of full-width buttons, and the progress indicator inside them.
  static const buttonHeight = 52.0;
  static const buttonProgressSize = 22.0;
  static const progressStrokeWidth = 2.5;
}
