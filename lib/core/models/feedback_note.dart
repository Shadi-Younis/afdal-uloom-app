import '../constants/firestore_paths.dart';
import '../constants/model_limits.dart';
import '../utils/map_reader.dart';
import 'feedback_kind.dart';

/// A note on a recording (`recordings/{id}/feedback/{id}`): a written
/// note of the teacher ([FeedbackKind.text]), or a place where the sheikh
/// spoke that the server found ([FeedbackKind.voice]), to which the
/// teacher may add text.
class FeedbackNote {
  /// Throws [ArgumentError] for a rating outside 1..5, a negative
  /// [atSecond], an [endSecond] before [atSecond] or without it, or an empty
  /// text note.
  ///
  /// Not const: a const constructor cannot run these checks, and asserts
  /// alone would vanish in release builds.
  FeedbackNote({
    required this.id,
    required this.teacherId,
    required this.note,
    this.kind = FeedbackKind.text,
    this.atSecond,
    this.endSecond,
    this.rating,
    required this.createdAt,
    this.updatedAt,
  }) {
    final at = atSecond;
    if (at != null && at < 0) {
      throw ArgumentError.value(at, 'atSecond', 'must be >= 0');
    }
    final end = endSecond;
    if (end != null && (at == null || end < at)) {
      throw ArgumentError.value(end, 'endSecond', 'must be >= atSecond');
    }
    if (kind == FeedbackKind.text && note.isEmpty) {
      throw ArgumentError.value(note, 'note', 'a text note needs text');
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
        // Notes written before Task 09 have no kind: they are text.
        kind: switch (readOptional<String>(map, Fields.kind)) {
          final kind? => FeedbackKind.fromValue(kind),
          null => FeedbackKind.text,
        },
        atSecond: readOptional<int>(map, Fields.atSecond),
        endSecond: readOptional<int>(map, Fields.endSecond),
        rating: readOptional<int>(map, Fields.rating),
        createdAt: readRequired<DateTime>(map, Fields.createdAt),
        updatedAt: readOptional<DateTime>(map, Fields.updatedAt),
      );

  /// The document id; not stored in the document.
  final String id;

  /// The author; for a voice marker, the recording's teacher.
  final String teacherId;

  /// The text; may be empty for a voice marker.
  final String note;
  final FeedbackKind kind;

  /// The moment in the recording this note is about, if any. A voice
  /// marker starts here (floored to the second).
  final int? atSecond;

  /// Where the sheikh stopped speaking (voice markers only).
  final int? endSecond;

  /// 1..5, if the teacher rated the recitation.
  final int? rating;
  final DateTime createdAt;

  /// When the teacher last edited the text or rating.
  final DateTime? updatedAt;

  bool get isVoice => kind == FeedbackKind.voice;

  Map<String, dynamic> toMap() => {
    Fields.teacherId: teacherId,
    Fields.note: note,
    Fields.kind: kind.value,
    Fields.atSecond: atSecond,
    Fields.endSecond: ?endSecond,
    Fields.rating: rating,
    Fields.createdAt: createdAt,
    Fields.updatedAt: ?updatedAt,
  };

  /// Nullable fields cannot be cleared to null through copyWith.
  FeedbackNote copyWith({
    String? id,
    String? teacherId,
    String? note,
    FeedbackKind? kind,
    int? atSecond,
    int? endSecond,
    int? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FeedbackNote(
    id: id ?? this.id,
    teacherId: teacherId ?? this.teacherId,
    note: note ?? this.note,
    kind: kind ?? this.kind,
    atSecond: atSecond ?? this.atSecond,
    endSecond: endSecond ?? this.endSecond,
    rating: rating ?? this.rating,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is FeedbackNote &&
      other.id == id &&
      other.teacherId == teacherId &&
      other.note == note &&
      other.kind == kind &&
      other.atSecond == atSecond &&
      other.endSecond == endSecond &&
      other.rating == rating &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    teacherId,
    note,
    kind,
    atSecond,
    endSecond,
    rating,
    createdAt,
    updatedAt,
  );

  @override
  String toString() =>
      'FeedbackNote(id: $id, ${kind.value}, teacherId: $teacherId, '
      'note: $note, atSecond: $atSecond, endSecond: $endSecond, '
      'rating: $rating, createdAt: $createdAt, updatedAt: $updatedAt)';
}
