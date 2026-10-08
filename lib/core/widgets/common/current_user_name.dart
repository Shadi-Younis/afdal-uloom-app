import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/session_providers.dart';
import '../../errors/app_exception.dart';
import 'error_view.dart';
import 'loading_view.dart';

/// The signed-in user's full name, with loading and error states.
class CurrentUserName extends ConsumerWidget {
  const CurrentUserName({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(currentUserProvider)) {
      AsyncData(value: final user?) => Text(
        user.fullName,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      // Signed in, but the profile document is missing.
      AsyncData(value: null) => const ErrorView(
        error: AppException(AppErrorCode.notFound),
      ),
      AsyncError(:final error) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(currentUserProvider),
      ),
      _ => const LoadingView(),
    };
  }
}
