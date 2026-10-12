/// What a note on a recording is (`feedback/{id}.kind`). [value] is what
/// Firestore stores; a note without `kind` (written before Task 09) is
/// [text].
enum FeedbackKind {
  /// A place where the sheikh spoke, found by the server in his channel.
  /// Its text may be empty.
  voice('voice'),

  /// A note the teacher wrote.
  text('text');

  const FeedbackKind(this.value);

  final String value;

  /// Throws [FormatException] for a string that is not a known kind.
  static FeedbackKind fromValue(String value) => values.firstWhere(
    (kind) => kind.value == value,
    orElse: () => throw FormatException('Unknown feedback kind', value),
  );
}
