import 'dart:async';

import 'package:afdal_uloom_tilawat/core/models/recording.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_type.dart';
import 'package:afdal_uloom_tilawat/core/repositories/recording_repository.dart';

/// A [RecordingRepository] over an in-memory map. Streams emit again after
/// every write.
///
/// - [watchError] / [getError] / [createError] / [deleteError]: thrown or
///   emitted instead of the normal result.
/// - [createGate]: when set, create waits for it.
/// - [getGate] / [watchGate]: when set, get / watch wait for it (to test
///   loading states).
class FakeRecordingRepository implements RecordingRepository {
  FakeRecordingRepository([List<Recording> recordings = const []])
    : recordings = {for (final r in recordings) r.id: r};

  final Map<String, Recording> recordings;
  Object? watchError;
  Object? getError;
  Object? createError;
  Object? deleteError;
  Completer<void>? createGate;
  Completer<void>? getGate;
  Completer<void>? watchGate;

  final created = <Recording>[];
  final deleted = <String>[];
  var _nextId = 0;

  final _changed = StreamController<void>.broadcast();

  @override
  Stream<List<Recording>> watchForStudent(
    String studentId, {
    String? teacherId,
  }) => _live(
    () =>
        recordings.values
            .where(
              (r) =>
                  r.studentId == studentId &&
                  (teacherId == null || r.teacherId == teacherId),
            )
            .toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt)),
  );

  @override
  Stream<List<Recording>> watchPendingPractice(String teacherId) =>
      throw UnimplementedError();

  @override
  Future<Recording?> get(String id) async {
    await getGate?.future;
    if (getError case final error?) throw error;
    return recordings[id];
  }

  @override
  String newId() => 'new-${++_nextId}';

  @override
  Future<void> create(Recording recording) async {
    await createGate?.future;
    if (createError case final error?) throw error;
    created.add(recording);
    recordings[recording.id] = recording;
    _changed.add(null);
  }

  @override
  Future<void> markFeedbackRead(String id) => throw UnimplementedError();

  @override
  Future<void> markReviewed(String id) => throw UnimplementedError();

  @override
  Future<void> delete(String id) async {
    if (deleteError case final error?) throw error;
    deleted.add(id);
    recordings.remove(id);
    _changed.add(null);
  }

  Stream<T> _live<T>(T Function() read) async* {
    await watchGate?.future;
    if (watchError case final error?) throw error;
    yield read();
    yield* _changed.stream.map((_) => read());
  }
}

/// A recording as the seed has them: official, s001 of حلقة الفجر.
Recording sampleRecording(
  String id, {
  String studentId = 's001',
  RecordingType type = RecordingType.official,
  int surahNumber = 2,
  int ayahFrom = 1,
  int ayahTo = 20,
  DateTime? recordedAt,
  bool unreadFeedback = false,
  String uploadedBy = 't01',
}) => Recording(
  id: id,
  studentId: studentId,
  halaqaId: 'halaqa-fajr',
  teacherId: 't01',
  uploadedBy: uploadedBy,
  type: type,
  surahNumber: surahNumber,
  ayahFrom: ayahFrom,
  ayahTo: ayahTo,
  storagePath: 'recordings/$studentId/$id.wav',
  durationSec: 30,
  recordedAt: recordedAt ?? DateTime(2026, 9, 8, 16),
  createdAt: recordedAt ?? DateTime(2026, 9, 8, 18),
  unreadFeedback: unreadFeedback,
  reviewed: type == RecordingType.official,
);
