import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/service_providers.dart';

/// Sign-out, shared by every role's home screen. The router reacts to the
/// session ending; this only exposes loading and errors.
class SessionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signOut() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signOut(),
    );
    if (ref.mounted) state = result;
  }
}

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, void>(SessionController.new);
