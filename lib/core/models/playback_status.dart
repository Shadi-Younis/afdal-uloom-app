/// What the audio player is doing.
enum PlaybackStatus {
  /// Nothing loaded.
  idle,

  /// Loading the audio, or buffering while playing.
  loading,

  /// Loaded and stopped.
  paused,

  /// Playing.
  playing,

  /// Reached the end (and stopped).
  completed,
}
