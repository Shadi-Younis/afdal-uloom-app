/// The audio files the app accepts.
abstract final class AudioFormats {
  /// The Storage content type of each accepted file extension. The keys are
  /// the extensions firestore.rules allows in a recording's storagePath;
  /// storage.rules accepts any `audio/*` type.
  static const contentTypes = {
    'mp3': 'audio/mpeg',
    'm4a': 'audio/mp4',
    'aac': 'audio/aac',
    'wav': 'audio/wav',
    'ogg': 'audio/ogg',
    'webm': 'audio/webm',
  };

  /// Uploads must be smaller than this (100 MiB): long studio sessions as
  /// MP3 can pass 30 MB. Must match maxUploadBytes() in storage.rules.
  static const maxUploadBytes = 100 * 1024 * 1024;

  /// The content type for [extension] (any case, without the dot), or null
  /// when the app does not accept it.
  static String? contentTypeFor(String extension) =>
      contentTypes[extension.toLowerCase()];
}
