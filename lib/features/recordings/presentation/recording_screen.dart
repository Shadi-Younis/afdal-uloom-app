import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/common/error_view.dart';
import '../../../core/widgets/common/loading_view.dart';
import '../application/recording_details_providers.dart';
import 'widgets/recording_details_view.dart';

/// One recording, for every role: title, type, date, uploader, the player
/// and the teacher's notes. Another student's recording shows the
/// permission error (the rules refuse it).
class RecordingScreen extends ConsumerWidget {
  const RecordingScreen({super.key, required this.recordingId});

  final String recordingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recording = ref.watch(recordingDetailsProvider(recordingId));
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.recordingScreenTitle),
        // Opened from a link there is nothing to go back to: the splash
        // route sends each role to its home.
        leading: Navigator.of(context).canPop()
            ? null
            : IconButton(
                tooltip: AppStrings.home,
                icon: const Icon(Icons.home_outlined),
                onPressed: () => context.go(AppRoutes.splash),
              ),
      ),
      body: SafeArea(
        child: switch (recording) {
          AsyncData(value: final recording?) => RecordingDetailsView(
            recording: recording,
          ),
          AsyncData() => const ErrorView(
            error: AppException(AppErrorCode.notFound),
          ),
          AsyncError(:final error) => ErrorView(
            error: error,
            onRetry: () =>
                ref.invalidate(recordingDetailsProvider(recordingId)),
          ),
          _ => const LoadingView(),
        },
      ),
    );
  }
}
