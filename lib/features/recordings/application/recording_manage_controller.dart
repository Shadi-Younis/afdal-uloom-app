import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';

/// The quick actions on one recording: delete a note and «تمت المراجعة»
/// (its teacher, admins), «حذف التدريب» (its student). Loading while one
/// runs; an error stays in the state for the screen to show.
class RecordingManageController extends AsyncNotifier<void> {
  RecordingManageController(this.recordingId);

  final String recordingId;

  @override
  FutureOr<void> build() {}

  /// Whether the note was deleted.
  Future<bool> deleteNote(String feedbackId) => _run(
    () => ref.read(feedbackRepositoryProvider).delete(recordingId, feedbackId),
  );

  /// Whether the recording was deleted (its file and notes follow, by the
  /// server).
  Future<bool> deleteRecording() =>
      _run(() => ref.read(recordingRepositoryProvider).delete(recordingId));

  /// Whether `reviewed` was changed.
  Future<bool> setReviewed({required bool reviewed}) => _run(
    () => ref
        .read(recordingRepositoryProvider)
        .setReviewed(recordingId, reviewed: reviewed),
  );

  Future<bool> _run(Future<void> Function() action) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}

final recordingManageControllerProvider = AsyncNotifierProvider.autoDispose
    .family<RecordingManageController, void, String>(
      RecordingManageController.new,
    );
