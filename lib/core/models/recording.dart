import '../constants/firestore_paths.dart';
import '../constants/model_limits.dart';
import '../utils/map_reader.dart';
import 'analysis_status.dart';
import 'recording_analysis.dart';
import 'recording_source.dart';
import 'recording_type.dart';
import 'stem_paths.dart';

/// A recitation (`recordings/{id}`). The audio file lives in Storage at
/// [storagePath]; Firestore never stores a download URL.
class Recording {
  /// Throws [ArgumentError] for a surah outside 1..114, ayat without a
  /// surah, only one of the two ayat, an ayahFrom below 1, an ayahFrom
  /// after ayahTo or a negative duration. Surah and ayat are optional:
  /// none, a surah alone, or a surah with both ayat.
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
    this.surahNumber,
    this.ayahFrom,
    this.ayahTo,
    required this.storagePath,
    this.durationSec,
    required this.recordedAt,
    required this.createdAt,
    required this.unreadFeedback,
    required this.reviewed,
    this.source = RecordingSource.stereo,
    this.stemPaths,
    this.analysis,
    this.playbackPath,
  }) {
    final (surah, from, to) = (surahNumber, ayahFrom, ayahTo);
    if (surah != null &&
        (surah < ModelLimits.surahMin || surah > ModelLimits.surahMax)) {
      throw ArgumentError.value(surah, 'surahNumber', 'must be 1..114');
    }
    if ((from == null) != (to == null)) {
      throw ArgumentError.value(to, 'ayahTo', 'both ayat or neither');
    }
    if (from != null && to != null) {
      if (surah == null) {
        throw ArgumentError.value(from, 'ayahFrom', 'ayat need a surah');
      }
      if (from < ModelLimits.ayahMin) {
        throw ArgumentError.value(from, 'ayahFrom', 'must be >= 1');
      }
      if (from > to) {
        throw ArgumentError.value(to, 'ayahTo', 'must be >= ayahFrom');
      }
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
    surahNumber: readOptional<int>(map, Fields.surahNumber),
    ayahFrom: readOptional<int>(map, Fields.ayahFrom),
    ayahTo: readOptional<int>(map, Fields.ayahTo),
    storagePath: readRequired<String>(map, Fields.storagePath),
    durationSec: readOptional<int>(map, Fields.durationSec),
    recordedAt: readRequired<DateTime>(map, Fields.recordedAt),
    createdAt: readRequired<DateTime>(map, Fields.createdAt),
    unreadFeedback: readRequired<bool>(map, Fields.unreadFeedback),
    reviewed: readRequired<bool>(map, Fields.reviewed),
    source: RecordingSource.fromValue(readOptional<String>(map, Fields.source)),
    stemPaths: switch (readOptional<Map<String, dynamic>>(
      map,
      Fields.stemPaths,
    )) {
      final paths? => StemPaths.fromMap(paths),
      null => null,
    },
    analysis: switch (readOptional<Map<String, dynamic>>(
      map,
      Fields.analysis,
    )) {
      final analysis? => RecordingAnalysis.fromMap(analysis),
      null => null,
    },
    playbackPath: readOptional<String>(map, Fields.playbackPath),
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
  /// Null when the teacher left it out (official recordings only).
  final int? surahNumber;

  /// Both or neither, and only with a surah.
  final int? ayahFrom;
  final int? ayahTo;

  /// `recordings/{studentId}/{id}.{ext}`, see StoragePaths.recording.
  final String storagePath;
  final int? durationSec;
  final DateTime recordedAt;
  final DateTime createdAt;

  /// For the student: a teacher note they have not read yet.
  final bool unreadFeedback;

  /// For the teacher: whether they reviewed this recording (an official
  /// one's voice markers, a practice one's recitation).
  final bool reviewed;

  /// How the studio exported it: one stereo file, or two files the server
  /// joins into [storagePath].
  final RecordingSource source;

  /// The two files of a [RecordingSource.stems] recording; null otherwise.
  final StemPaths? stemPaths;

  /// The server's analysis of an official recording; null before the file
  /// arrived, and for practice recordings (never analysed).
  final RecordingAnalysis? analysis;

  /// The centred copy for listening (StoragePaths.playback), once the
  /// server made it.
  final String? playbackPath;

  /// What the player plays: the centred copy when there is one.
  String get playablePath => playbackPath ?? storagePath;

  /// Whether [storagePath] holds the audio. A two-file recording has none
  /// until the server joined its files: while they upload or are being
  /// joined, and for good when joining them failed.
  bool get hasAudio => switch (source) {
    RecordingSource.stereo => true,
    RecordingSource.stems => switch (analysis) {
      null => false,
      final analysis => switch (analysis.status) {
        AnalysisStatus.merging => false,
        AnalysisStatus.failed => !analysis.isStemsFailure,
        AnalysisStatus.pending ||
        AnalysisStatus.done ||
        AnalysisStatus.mono => true,
      },
    },
  };

  Map<String, dynamic> toMap() => {
    Fields.studentId: studentId,
    Fields.halaqaId: halaqaId,
    Fields.teacherId: teacherId,
    Fields.uploadedBy: uploadedBy,
    Fields.type: type.value,
    // Left out when not given (firestore.rules: absent or null).
    Fields.surahNumber: ?surahNumber,
    Fields.ayahFrom: ?ayahFrom,
    Fields.ayahTo: ?ayahTo,
    Fields.storagePath: storagePath,
    Fields.durationSec: durationSec,
    Fields.recordedAt: recordedAt,
    Fields.createdAt: createdAt,
    Fields.unreadFeedback: unreadFeedback,
    Fields.reviewed: reviewed,
    // Left out for a stereo recording: documents from before Task 11 have
    // no source, and stereo is what a missing one means.
    if (source != RecordingSource.stereo) Fields.source: source.value,
    Fields.stemPaths: ?stemPaths?.toMap(),
    // Server-written: left out while unset, so a new recording's document
    // has only the fields a client may create (firestore.rules).
    Fields.analysis: ?analysis?.toMap(),
    Fields.playbackPath: ?playbackPath,
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
    RecordingSource? source,
    StemPaths? stemPaths,
    RecordingAnalysis? analysis,
    String? playbackPath,
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
    source: source ?? this.source,
    stemPaths: stemPaths ?? this.stemPaths,
    analysis: analysis ?? this.analysis,
    playbackPath: playbackPath ?? this.playbackPath,
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
      other.reviewed == reviewed &&
      other.source == source &&
      other.stemPaths == stemPaths &&
      other.analysis == analysis &&
      other.playbackPath == playbackPath;

  @override
  int get hashCode => Object.hashAll([
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
    source,
    stemPaths,
    analysis,
    playbackPath,
  ]);

  @override
  String toString() =>
      'Recording(id: $id, studentId: $studentId, halaqaId: $halaqaId, '
      'teacherId: $teacherId, uploadedBy: $uploadedBy, type: ${type.value}, '
      'surah: $surahNumber, ayat: $ayahFrom-$ayahTo, '
      'storagePath: $storagePath, durationSec: $durationSec, '
      'recordedAt: $recordedAt, createdAt: $createdAt, '
      'unreadFeedback: $unreadFeedback, reviewed: $reviewed, '
      'source: ${source.value}, stemPaths: $stemPaths, '
      'analysis: $analysis, playbackPath: $playbackPath)';
}
