import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/islamic/error_state.dart';
import '../../../../core/widgets/islamic/loading_state.dart';
import '../../application/admin_data_providers.dart';

/// Shows [value] with [builder] once it has data; the shared loading and
/// error views until then. Retry re-subscribes to the admin streams every
/// admin value is derived from.
class AdminAsyncView<T> extends ConsumerWidget {
  const AdminAsyncView({super.key, required this.value, required this.builder});

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (value) {
      AsyncData(:final value) => builder(context, value),
      AsyncError(:final error) => ErrorState(
        error: error,
        onRetry: () => ref
          ..invalidate(adminHalaqatProvider)
          ..invalidate(adminTeachersProvider)
          ..invalidate(adminStudentsProvider),
      ),
      _ => const LoadingState(),
    };
  }
}
