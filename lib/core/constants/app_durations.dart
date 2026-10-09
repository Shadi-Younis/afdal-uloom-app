/// Timeouts and animation durations.
abstract final class AppDurations {
  /// Longest wait for a single Firebase call before giving up.
  static const firebaseCallTimeout = Duration(seconds: 20);

  /// How far the player's back / forward buttons jump.
  static const playerSkip = Duration(seconds: 5);
}
