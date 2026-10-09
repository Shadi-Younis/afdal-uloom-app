/// Spacing, paddings, radii and icon / logo sizes, in logical pixels.
abstract final class AppSizes {
  // Spacing scale, used for paddings and gaps.
  static const spaceXS = 4.0;
  static const spaceS = 12.0;
  static const spaceM = 16.0;
  static const spaceL = 24.0;
  static const spaceXL = 32.0;

  /// Outer padding of full-screen forms such as login.
  static const screenPadding = spaceL;

  /// Outer padding of lists and details pages: tighter than forms, so a
  /// 360 px phone keeps room for the content.
  static const pagePadding = spaceM;

  /// The school logo on the login screen.
  static const logoLarge = 160.0;

  /// The school logo on the start-up screen.
  static const logoMedium = 120.0;

  /// Height of full-width buttons, and the progress indicator inside them.
  static const buttonHeight = 52.0;
  static const buttonProgressSize = 22.0;
  static const progressStrokeWidth = 2.5;

  /// From this width on (the studio PC) the admin panel shows a side rail
  /// instead of the bottom navigation bar.
  static const wideLayoutMinWidth = 600.0;

  /// Forms and details pages stay this narrow on wide screens.
  static const contentMaxWidth = 640.0;

  /// Room under a list so the floating action button never hides its last
  /// item.
  static const fabClearance = 88.0;

  /// The icon of an empty state.
  static const emptyIcon = 56.0;

  /// Every player button is at least this big (Material's touch target).
  static const touchTarget = 48.0;

  /// The player's play / pause button and its icon.
  static const playButton = 64.0;
  static const playIcon = 36.0;

  /// The back / forward 5 s icons.
  static const skipIcon = 30.0;
}
