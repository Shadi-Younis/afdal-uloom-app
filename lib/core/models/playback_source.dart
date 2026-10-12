// The subclasses must live in this file: Dart only allows subclasses of a
// sealed class in its own library (as in audio_source.dart).

/// What the player plays: a recording's file in Storage, or audio on this
/// device (the practice the student just recorded, before it is sent).
/// Used as the key of the player's provider, so it has value equality.
sealed class PlaybackSource {
  const PlaybackSource();
}

/// A file in Cloud Storage, e.g. `recording.playablePath`; its URL comes
/// from AudioStorageService.
class StoredPlayback extends PlaybackSource {
  const StoredPlayback(this.storagePath);

  final String storagePath;

  @override
  bool operator ==(Object other) =>
      other is StoredPlayback && other.storagePath == storagePath;

  @override
  int get hashCode => storagePath.hashCode;

  @override
  String toString() => 'StoredPlayback($storagePath)';
}

/// Audio on this device: a file URI (Android, iOS) or a blob URL (web).
class LocalPlayback extends PlaybackSource {
  const LocalPlayback(this.uri);

  final Uri uri;

  @override
  bool operator ==(Object other) => other is LocalPlayback && other.uri == uri;

  @override
  int get hashCode => uri.hashCode;

  @override
  String toString() => 'LocalPlayback($uri)';
}
