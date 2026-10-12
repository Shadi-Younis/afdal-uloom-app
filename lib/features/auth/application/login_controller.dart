import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/sign_out_notice_controller.dart';
import '../../../core/providers/service_providers.dart';
import 'login_validation_error.dart';

/// The login form's state: idle, loading, or an error, which is either a
/// [LoginValidationError] or an AppException from AuthService. On success
/// the router leaves the login screen by itself (the session changes).
class LoginController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signIn(String username, String password) async {
    if (state.isLoading) return;
    // A new attempt: why the last session ended no longer matters.
    ref.read(signOutNoticeProvider.notifier).clear();
    final problem = username.trim().isEmpty
        ? LoginValidationError.usernameRequired
        : password.isEmpty
        ? LoginValidationError.passwordRequired
        : null;
    if (problem != null) {
      state = AsyncError(problem, StackTrace.current);
      return;
    }

    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signIn(username, password),
    );
    // On success the login screen may already be gone (and this disposed).
    if (ref.mounted) state = result;
  }
}

final loginControllerProvider =
    AsyncNotifierProvider.autoDispose<LoginController, void>(
      LoginController.new,
    );
