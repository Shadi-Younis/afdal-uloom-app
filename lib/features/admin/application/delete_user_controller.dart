import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/service_providers.dart';

/// Deletes one teacher or student ([uid]) for good. Loading while the call
/// runs; an [AppException] on failure (`teacherOwnsHalaqat`, `network`,
/// ...). The users stream then drops them.
class DeleteUserController extends AsyncNotifier<void> {
  DeleteUserController(this.uid);

  final String uid;

  @override
  FutureOr<void> build() {}

  /// How many recordings were deleted with the account, or null when it was
  /// not deleted (the reason is in the state).
  Future<int?> delete() async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    final int recordingsDeleted;
    try {
      recordingsDeleted = await ref
          .read(accountsServiceProvider)
          .deleteUser(uid);
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(AppException.wrap(error, stackTrace), stackTrace);
      }
      return null;
    }
    if (ref.mounted) state = const AsyncData(null);
    return recordingsDeleted;
  }

  /// Whether [typed] is exactly [code]: the student's code must be typed to
  /// confirm a permanent delete. Exact on purpose (case and spaces count),
  /// so the admin reads the code instead of guessing it.
  static bool confirms(String typed, String code) =>
      code.isNotEmpty && typed == code;
}

final deleteUserControllerProvider = AsyncNotifierProvider.autoDispose
    .family<DeleteUserController, void, String>(DeleteUserController.new);
