/// Where the practice recorder is.
enum RecorderPhase {
  /// Nothing recorded yet; the big button starts.
  ready,

  /// Asking for the microphone, then opening it.
  starting,
  recording,
  paused,

  /// Closing the take.
  stopping,

  /// A take to listen to, then send or record again.
  recorded,

  /// The microphone was refused: the page explains how to allow it.
  permissionDenied;

  /// A take is being made: leaving the page loses it.
  bool get isCapturing =>
      this == starting ||
      this == recording ||
      this == paused ||
      this == stopping;
}
