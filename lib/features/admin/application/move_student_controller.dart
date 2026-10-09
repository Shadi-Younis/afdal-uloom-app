import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/service_providers.dart';

/// Moves one student ([studentId]) to another halaqa, with their
/// recordings. Loading while the call runs; an [AppException] on failure.
class MoveStudentController extends AsyncNotifier<void> {
  MoveStudentController(this.studentId);

  final String studentId;

  @override
  FutureOr<void> build() {}

  /// Whether the student was moved.
  Future<bool> move(String halaqaId) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await ref
          .read(accountsServiceProvider)
          .moveStudent(studentId: studentId, halaqaId: halaqaId);
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(AppException.wrap(error, stackTrace), stackTrace);
      }
      return false;
    }
    if (ref.mounted) state = const AsyncData(null);
    return true;
  }
}

final moveStudentControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MoveStudentController, void, String>(MoveStudentController.new);
