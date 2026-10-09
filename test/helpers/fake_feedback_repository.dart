import 'dart:async';

import 'package:afdal_uloom_tilawat/core/models/feedback_note.dart';
import 'package:afdal_uloom_tilawat/core/repositories/feedback_repository.dart';

/// A read-only [FeedbackRepository] over notes per recording id.
/// [watchError], when set, is emitted instead of the notes.
class FakeFeedbackRepository implements FeedbackRepository {
  FakeFeedbackRepository([Map<String, List<FeedbackNote>>? notes])
    : notes = notes ?? {};

  final Map<String, List<FeedbackNote>> notes;
  Object? watchError;

  @override
  Stream<List<FeedbackNote>> watch(String recordingId) async* {
    if (watchError case final error?) throw error;
    yield notes[recordingId] ?? const [];
  }

  @override
  Future<void> add(String recordingId, FeedbackNote note) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String recordingId, String feedbackId) =>
      throw UnimplementedError();
}
