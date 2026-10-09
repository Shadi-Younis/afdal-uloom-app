import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/service_providers.dart';

/// Deletes one empty halaqa ([halaqaId]). Loading while the call runs; an
/// [AppException] on failure (`halaqaHasStudents`, `halaqaHasRecordings`,
/// `network`, ...). The halaqat stream then drops it.
class DeleteHalaqaController extends AsyncNotifier<void> {
  DeleteHalaqaController(this.halaqaId);

  final String halaqaId;

  @override
  FutureOr<void> build() {}

  /// Whether the halaqa was deleted.
  Future<bool> delete() async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await ref.read(accountsServiceProvider).deleteHalaqa(halaqaId);
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

final deleteHalaqaControllerProvider = AsyncNotifierProvider.autoDispose
    .family<DeleteHalaqaController, void, String>(DeleteHalaqaController.new);
