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
}
