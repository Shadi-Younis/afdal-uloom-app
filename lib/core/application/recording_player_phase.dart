/// Whether the recording player can be used.
enum RecordingPlayerPhase {
  /// Getting the URL and loading the audio.
  loading,

  /// Loaded: the controls work.
  ready,

  /// Could not load, even with a fresh URL; see the state's error.
  error,
}
