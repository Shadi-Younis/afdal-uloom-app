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
  static const logoLarge = 150.0;

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

  /// The upload page is wider on the studio PC: each file's fields fit in
  /// two columns.
  static const uploadMaxWidth = 960.0;

  /// From this card width on, an uploaded file's fields go in two columns.
  static const uploadTwoColumnsMinWidth = 560.0;

  /// Material's floating action button: its height (also extended) and its
  /// distance from the bottom of the page.
  static const fabHeight = 56.0;
  static const fabMargin = 16.0;

  /// Room under a list so the floating action button never hides its last
  /// item: the button, its margin and a clear gap above it (its shadow
  /// alone made the last card look covered).
  static const fabClearance = fabHeight + fabMargin + spaceL;

  /// The icon of an empty state.
  static const emptyIcon = 56.0;

  // Design (docs/design/): corner radii and borders.
  static const radiusCard = 16.0;
  static const radiusButton = 14.0;
  static const radiusField = 14.0;
  static const radiusDialog = 20.0;
  static const radiusSheet = 24.0;
  static const radiusChip = 20.0;
  static const radiusSnackBar = 12.0;

  /// The green header's bottom corners.
  static const radiusHeader = 28.0;

  /// Gold hairlines around cards, fields and buttons.
  static const hairline = 1.0;

  /// The green border of a focused field.
  static const focusBorder = 1.5;

  /// The soft green shadow under cards: blur and vertical offset.
  static const cardShadowBlur = 12.0;
  static const cardShadowOffset = 4.0;

  /// Height of the player's progress bar.
  static const playerTrack = 6.0;

  /// The icon inside a small chip (recording type).
  static const chipIcon = 18.0;

  /// The "new feedback" dot on a recording.
  static const unreadDot = 10.0;

  /// The stars of a teacher's rating.
  static const ratingStar = 20.0;

  /// Every player button is at least this big (Material's touch target).
  static const touchTarget = 48.0;

  /// The player's play / pause button and its icon.
  static const playButton = 64.0;
  static const playIcon = 36.0;

  /// The gold halo around the play button.
  static const playHalo = 4.0;

  /// The back / forward 5 s icons.
  static const skipIcon = 30.0;

  /// A marker of the sheikh on the seek bar (IslamicStar), the lane of
  /// markers above the bar, and the gold band of a voice marker's span.
  static const markerStar = 18.0;
  static const markerLane = 26.0;
  static const markerBand = 14.0;

  /// The tappable width around a marker's star.
  static const markerHitWidth = 32.0;

  /// The practice recorder's big round button, its icon and its gold halo.
  static const recordButton = 96.0;
  static const recordIcon = 44.0;
  static const recordHalo = 6.0;

  /// The recorder's small pause / stop buttons.
  static const recorderSideButton = 56.0;

  /// The height of the recorder's live level meter.
  static const levelMeter = 10.0;
}
