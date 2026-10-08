import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/service_providers.dart';

/// Disables or enables one account ([uid]). Loading while the call runs;
/// an [AppException] on failure. The users stream then shows the change.
class SetUserDisabledController extends AsyncNotifier<void> {
  SetUserDisabledController(this.uid);

  final String uid;

  @override
  FutureOr<void> build() {}

  /// Whether the account is now [disabled].
  Future<bool> setDisabled(bool disabled) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await ref
          .read(accountsServiceProvider)
          .setUserDisabled(uid: uid, disabled: disabled);
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

final setUserDisabledControllerProvider = AsyncNotifierProvider.autoDispose
    .family<SetUserDisabledController, void, String>(
      SetUserDisabledController.new,
    );
