/// Typed reads from a document map for `fromMap` factories. Every reader
/// throws [FormatException] naming the field when it is missing or has the
/// wrong type, so a bad document fails loudly instead of as a cast error.
library;

T readRequired<T extends Object>(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) {
    throw FormatException('Missing required field "$key"', map);
  }
  if (value is! T) {
    throw FormatException(
      'Field "$key" must be $T, got ${value.runtimeType}',
      map,
    );
  }
  return value;
}

T? readOptional<T extends Object>(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! T) {
    throw FormatException(
      'Field "$key" must be $T or null, got ${value.runtimeType}',
      map,
    );
  }
  return value;
}

/// A list of strings; a missing field reads as an empty list.
List<String> readStringList(Map<String, dynamic> map, String key) {
  final value = readOptional<List<Object?>>(map, key) ?? const [];
  if (value.any((e) => e is! String)) {
    throw FormatException('Field "$key" must contain only strings', map);
  }
  return List.unmodifiable(value.cast<String>());
}
