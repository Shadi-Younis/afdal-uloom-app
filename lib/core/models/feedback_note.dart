import '../constants/firestore_paths.dart';
import '../constants/model_limits.dart';
import '../utils/map_reader.dart';

/// A teacher's note on a recording (`recordings/{id}/feedback/{id}`).
class FeedbackNote {
  /// Throws [ArgumentError] for a rating outside 1..5 or a negative
  /// [atSecond].
  ///
  /// Not const: a const constructor cannot run these checks, and asserts
  /// alone would vanish in release builds.
  FeedbackNote({
    required this.id,
    required this.teacherId,
    required this.note,
    this.atSecond,
    this.rating,
    required this.createdAt,
  }) {
    final at = atSecond;
    if (at != null && at < 0) {
      throw ArgumentError.value(at, 'atSecond', 'must be >= 0');
    }
    final stars = rating;
    if (stars != null &&
        (stars < ModelLimits.ratingMin || stars > ModelLimits.ratingMax)) {
      throw ArgumentError.value(stars, 'rating', 'must be 1..5');
    }
  }

  /// Throws [FormatException] for a missing field or a wrong type, and
  /// [ArgumentError] for out-of-range values.
  factory FeedbackNote.fromMap(String id, Map<String, dynamic> map) =>
      FeedbackNote(
        id: id,
        teacherId: readRequired<String>(map, Fields.teacherId),
        note: readRequired<String>(map, Fields.note),
        atSecond: readOptional<int>(map, Fields.atSecond),
        rating: readOptional<int>(map, Fields.rating),
        createdAt: readRequired<DateTime>(map, Fields.createdAt),
      );

  /// The document id; not stored in the document.
  final String id;

  /// The author.
  final String teacherId;
  final String note;

  /// The moment in the recording this note is about, if any.
  final int? atSecond;

  /// 1..5, if the teacher rated the recitation.
  final int? rating;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    Fields.teacherId: teacherId,
    Fields.note: note,
    Fields.atSecond: atSecond,
    Fields.rating: rating,
    Fields.createdAt: createdAt,
  };

  /// Nullable fields cannot be cleared to null through copyWith.
  FeedbackNote copyWith({
    String? id,
    String? teacherId,
    String? note,
    int? atSecond,
    int? rating,
    DateTime? createdAt,
  }) => FeedbackNote(
    id: id ?? this.id,
    teacherId: teacherId ?? this.teacherId,
    note: note ?? this.note,
    atSecond: atSecond ?? this.atSecond,
    rating: rating ?? this.rating,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  bool operator ==(Object other) =>
      other is FeedbackNote &&
      other.id == id &&
      other.teacherId == teacherId &&
      other.note == note &&
      other.atSecond == atSecond &&
      other.rating == rating &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, teacherId, note, atSecond, rating, createdAt);

  @override
  String toString() =>
      'FeedbackNote(id: $id, teacherId: $teacherId, note: $note, '
      'atSecond: $atSecond, rating: $rating, createdAt: $createdAt)';
}
