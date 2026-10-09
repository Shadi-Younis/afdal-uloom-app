import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/application/recording_player_controller.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/recording.dart';
import '../../../../core/widgets/islamic/empty_state.dart';
import '../../../../core/widgets/islamic/error_state.dart';
import '../../../../core/widgets/islamic/loading_state.dart';
import '../../application/recording_details_providers.dart';
import 'feedback_tile.dart';

/// The teacher's notes on [recording], read-only, one card each. A note's
/// "عند ٠١:٢٣" moves the player there.
class FeedbackSection extends ConsumerWidget {
  const FeedbackSection({super.key, required this.recording});

  final Recording recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(recordingFeedbackProvider(recording.id));
    final player = recordingPlayerControllerProvider(recording.storagePath);
    return switch (notes) {
      AsyncData(value: final notes) when notes.isEmpty => const EmptyState(
        message: AppStrings.noFeedback,
      ),
      AsyncData(value: final notes) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final note in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spaceS),
              child: FeedbackTile(
                note: note,
                onSeek: (position) => ref.read(player.notifier).seek(position),
              ),
            ),
        ],
      ),
      AsyncError(:final error) => ErrorState(
        error: error,
        onRetry: () => ref.invalidate(recordingFeedbackProvider(recording.id)),
      ),
      _ => const LoadingState(),
    };
  }
}
