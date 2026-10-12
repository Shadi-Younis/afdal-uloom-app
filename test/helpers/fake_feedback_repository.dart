import 'dart:async';

import 'package:afdal_uloom_tilawat/core/models/feedback_note.dart';
import 'package:afdal_uloom_tilawat/core/repositories/feedback_repository.dart';

/// A [FeedbackRepository] over notes per recording id. Streams emit again
/// after every write, like Firestore snapshots.
///
/// - [watchError]: emitted instead of the notes.
/// - [writeError]: thrown by add, update and delete.
/// - [writeGate]: when set, add, update and delete wait for it.
/// - [onUnread]: called with the recording id whenever a write would set
///   its `unreadFeedback` (add and update), like the real batch.
class FakeFeedbackRepository implements FeedbackRepository {
  FakeFeedbackRepository([Map<String, List<FeedbackNote>>? notes])
    : notes = notes ?? {};

  final Map<String, List<FeedbackNote>> notes;
  Object? watchError;
  Object? writeError;
  Completer<void>? writeGate;
  void Function(String recordingId)? onUnread;

  final added = <(String recordingId, FeedbackNote note)>[];
  final updated =
      <(String recordingId, String feedbackId, String note, int? rating)>[];
  final deleted = <(String recordingId, String feedbackId)>[];

  var _nextId = 0;
  final _changed = StreamController<void>.broadcast();

  /// The time given to new notes and edits.
  DateTime now = DateTime(2026, 10, 11, 12);

  @override
  Stream<List<FeedbackNote>> watch(String recordingId) async* {
    if (watchError case final error?) throw error;
    yield _read(recordingId);
    yield* _changed.stream.map((_) => _read(recordingId));
  }

  /// Replaces the notes of [recordingId], as the server or another device
  /// would; every open stream emits again.
  void put(String recordingId, List<FeedbackNote> list) {
    notes[recordingId] = [...list];
    _changed.add(null);
  }

  List<FeedbackNote> _read(String recordingId) =>
      List.unmodifiable(notes[recordingId] ?? const <FeedbackNote>[]);

  @override
  Future<void> add(String recordingId, FeedbackNote note) async {
    await _beforeWrite();
    final stored = note.copyWith(id: 'fb-new-${++_nextId}', createdAt: now);
    added.add((recordingId, stored));
    (notes[recordingId] ??= []).add(stored);
    onUnread?.call(recordingId);
    _changed.add(null);
  }

  @override
  Future<void> update(
    String recordingId,
    String feedbackId, {
    required String note,
    int? rating,
  }) async {
    await _beforeWrite();
    updated.add((recordingId, feedbackId, note, rating));
    final list = notes[recordingId] ?? [];
    final index = list.indexWhere((n) => n.id == feedbackId);
    if (index >= 0) {
      final old = list[index];
      // copyWith cannot clear the rating; build the note again.
      list[index] = FeedbackNote(
        id: old.id,
        teacherId: old.teacherId,
        note: note,
        kind: old.kind,
        atSecond: old.atSecond,
        endSecond: old.endSecond,
        rating: rating,
        createdAt: old.createdAt,
        updatedAt: now,
      );
    }
    onUnread?.call(recordingId);
    _changed.add(null);
  }

  @override
  Future<void> delete(String recordingId, String feedbackId) async {
    await _beforeWrite();
    deleted.add((recordingId, feedbackId));
    notes[recordingId]?.removeWhere((n) => n.id == feedbackId);
    _changed.add(null);
  }

  Future<void> _beforeWrite() async {
    await writeGate?.future;
    if (writeError case final error?) throw error;
  }
}
