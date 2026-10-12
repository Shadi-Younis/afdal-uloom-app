/// Timeouts and animation durations.
abstract final class AppDurations {
  /// Longest wait for a single Firebase call before giving up.
  static const firebaseCallTimeout = Duration(seconds: 20);

  /// How long a message stays at the bottom of the screen (Material's
  /// default).
  static const snackBar = Duration(seconds: 4);

  /// A second Android back within this time on a home screen exits.
  static const exitConfirmWindow = Duration(seconds: 2);

  /// How far the player's back / forward buttons jump.
  static const playerSkip = Duration(seconds: 5);

  /// An official recording without an analysis yet shows «جاري تحليل
  /// التسجيل…» for this long after it was created; older ones were
  /// uploaded before the analysis existed and show nothing.
  static const analysisPendingWindow = Duration(minutes: 30);

  /// «التالي» skips a marker the player is (almost) at, so pressing it
  /// right after a jump goes on to the following one.
  static const nextMarkerTolerance = Duration(milliseconds: 500);

  /// «السابق» this far into a marker goes to the one before it, not back
  /// to its own start.
  static const previousMarkerTolerance = Duration(milliseconds: 1500);

  /// The longest practice recording; the recorder stops by itself there.
  static const maxPracticeLength = Duration(minutes: 30);

  /// From here on the recorder warns that [maxPracticeLength] is near.
  static const practiceLengthWarning = Duration(minutes: 25);

  /// How often the recorder's timer and level meter refresh.
  static const recorderTick = Duration(milliseconds: 200);
}
