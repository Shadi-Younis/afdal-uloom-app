import '../constants/firestore_paths.dart';
import '../constants/model_limits.dart';
import '../utils/map_reader.dart';
import 'recording_type.dart';

/// A recitation (`recordings/{id}`). The audio file lives in Storage at
/// [storagePath]; Firestore never stores a download URL.
class Recording {
  /// Throws [ArgumentError] for a surah outside 1..114, an ayahFrom below 1,
  /// an ayahFrom after ayahTo or a negative duration.
  ///
  /// Not const: a const constructor cannot run these checks, and asserts
  /// alone would vanish in release builds.
  Recording({
    required this.id,
    required this.studentId,
    required this.halaqaId,
    required this.teacherId,
    required this.uploadedBy,
    required this.type,
    required this.surahNumber,
    required this.ayahFrom,
    required this.ayahTo,
    required this.storagePath,
    this.durationSec,
    required this.recordedAt,
    required this.createdAt,
    required this.unreadFeedback,
    required this.reviewed,
  }) {
    if (surahNumber < ModelLimits.surahMin ||
        surahNumber > ModelLimits.surahMax) {
      throw ArgumentError.value(surahNumber, 'surahNumber', 'must be 1..114');
    }
    if (ayahFrom < ModelLimits.ayahMin) {
      throw ArgumentError.value(ayahFrom, 'ayahFrom', 'must be >= 1');
    }
    if (ayahFrom > ayahTo) {
      throw ArgumentError.value(ayahTo, 'ayahTo', 'must be >= ayahFrom');
    }
    final duration = durationSec;
    if (duration != null && duration < 0) {
      throw ArgumentError.value(duration, 'durationSec', 'must be >= 0');
    }
  }

  /// Throws [FormatException] for a missing field, a wrong type or an unknown
  /// type, and [ArgumentError] for out-of-range values.
  factory Recording.fromMap(String id, Map<String, dynamic> map) => Recording(
    id: id,
    studentId: readRequired<String>(map, Fields.studentId),
    halaqaId: readRequired<String>(map, Fields.halaqaId),
    teacherId: readRequired<String>(map, Fields.teacherId),
    uploadedBy: readRequired<String>(map, Fields.uploadedBy),
    type: RecordingType.fromValue(readRequired<String>(map, Fields.type)),
    surahNumber: readRequired<int>(map, Fields.surahNumber),
    ayahFrom: readRequired<int>(map, Fields.ayahFrom),
    ayahTo: readRequired<int>(map, Fields.ayahTo),
    storagePath: readRequired<String>(map, Fields.storagePath),
    durationSec: readOptional<int>(map, Fields.durationSec),
    recordedAt: readRequired<DateTime>(map, Fields.recordedAt),
    createdAt: readRequired<DateTime>(map, Fields.createdAt),
    unreadFeedback: readRequired<bool>(map, Fields.unreadFeedback),
    reviewed: readRequired<bool>(map, Fields.reviewed),
  );

  /// The document id; not stored in the document.
  final String id;
  final String studentId;

  /// Copied from the student on purpose, for queries and rules.
  final String halaqaId;

  /// Copied from the halaqa on purpose, for queries and rules.
  final String teacherId;
  final String uploadedBy;
  final RecordingType type;

  /// 1..114 (2 = Al-Baqarah); the name comes from a list in the app.
  final int surahNumber;
  final int ayahFrom;
  final int ayahTo;

  /// `recordings/{studentId}/{id}.{ext}`, see StoragePaths.recording.
  final String storagePath;
  final int? durationSec;
  final DateTime recordedAt;
  final DateTime createdAt;

  /// For the student: a teacher note they have not read yet.
  final bool unreadFeedback;

  /// For the teacher: whether they reviewed this practice recording.
  final bool reviewed;

  Map<String, dynamic> toMap() => {
    Fields.studentId: studentId,
    Fields.halaqaId: halaqaId,
    Fields.teacherId: teacherId,
    Fields.uploadedBy: uploadedBy,
    Fields.type: type.value,
    Fields.surahNumber: surahNumber,
    Fields.ayahFrom: ayahFrom,
    Fields.ayahTo: ayahTo,
    Fields.storagePath: storagePath,
    Fields.durationSec: durationSec,
    Fields.recordedAt: recordedAt,
    Fields.createdAt: createdAt,
    Fields.unreadFeedback: unreadFeedback,
    Fields.reviewed: reviewed,
  };

  /// Nullable fields cannot be cleared to null through copyWith.
  Recording copyWith({
    String? id,
    String? studentId,
    String? halaqaId,
    String? teacherId,
    String? uploadedBy,
    RecordingType? type,
    int? surahNumber,
    int? ayahFrom,
    int? ayahTo,
    String? storagePath,
    int? durationSec,
    DateTime? recordedAt,
    DateTime? createdAt,
    bool? unreadFeedback,
    bool? reviewed,
  }) => Recording(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    halaqaId: halaqaId ?? this.halaqaId,
    teacherId: teacherId ?? this.teacherId,
    uploadedBy: uploadedBy ?? this.uploadedBy,
    type: type ?? this.type,
    surahNumber: surahNumber ?? this.surahNumber,
    ayahFrom: ayahFrom ?? this.ayahFrom,
    ayahTo: ayahTo ?? this.ayahTo,
    storagePath: storagePath ?? this.storagePath,
    durationSec: durationSec ?? this.durationSec,
    recordedAt: recordedAt ?? this.recordedAt,
    createdAt: createdAt ?? this.createdAt,
    unreadFeedback: unreadFeedback ?? this.unreadFeedback,
    reviewed: reviewed ?? this.reviewed,
  );

  @override
  bool operator ==(Object other) =>
      other is Recording &&
      other.id == id &&
      other.studentId == studentId &&
      other.halaqaId == halaqaId &&
      other.teacherId == teacherId &&
      other.uploadedBy == uploadedBy &&
      other.type == type &&
      other.surahNumber == surahNumber &&
      other.ayahFrom == ayahFrom &&
      other.ayahTo == ayahTo &&
      other.storagePath == storagePath &&
      other.durationSec == durationSec &&
      other.recordedAt == recordedAt &&
      other.createdAt == createdAt &&
      other.unreadFeedback == unreadFeedback &&
      other.reviewed == reviewed;

  @override
  int get hashCode => Object.hash(
    id,
    studentId,
    halaqaId,
    teacherId,
    uploadedBy,
    type,
    surahNumber,
    ayahFrom,
    ayahTo,
    storagePath,
    durationSec,
    recordedAt,
    createdAt,
    unreadFeedback,
    reviewed,
  );

  @override
  String toString() =>
      'Recording(id: $id, studentId: $studentId, halaqaId: $halaqaId, '
      'teacherId: $teacherId, uploadedBy: $uploadedBy, type: ${type.value}, '
      'surah: $surahNumber, ayat: $ayahFrom-$ayahTo, '
      'storagePath: $storagePath, durationSec: $durationSec, '
      'recordedAt: $recordedAt, createdAt: $createdAt, '
      'unreadFeedback: $unreadFeedback, reviewed: $reviewed)';
}
