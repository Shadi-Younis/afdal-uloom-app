import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/service_providers.dart';

/// Gives one halaqa ([halaqaId]) to another teacher, with its recordings.
/// Loading while the call runs; an [AppException] on failure.
class ChangeHalaqaTeacherController extends AsyncNotifier<void> {
  ChangeHalaqaTeacherController(this.halaqaId);

  final String halaqaId;

  @override
  FutureOr<void> build() {}

  /// Whether the teacher was changed.
  Future<bool> change(String teacherId) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await ref
          .read(accountsServiceProvider)
          .changeHalaqaTeacher(halaqaId: halaqaId, teacherId: teacherId);
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

final changeHalaqaTeacherControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ChangeHalaqaTeacherController, void, String>(
      ChangeHalaqaTeacherController.new,
    );
