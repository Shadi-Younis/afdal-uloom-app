import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/application/recording_player_controller.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/recording.dart';
import '../../../../core/widgets/islamic/empty_state.dart';
import '../../../../core/widgets/islamic/error_state.dart';
import '../../../../core/widgets/islamic/loading_state.dart';
import '../../application/note_order.dart';
import '../../application/recording_details_providers.dart';
import 'feedback_tile.dart';
import 'note_actions.dart';

/// The notes on [recording] in the order of the recitation, one card each:
/// the sheikh's voice markers and the written notes. Tapping a moment plays
/// from there. With [canManage] (its teacher, admins) each card has edit
/// and delete.
class FeedbackSection extends ConsumerWidget {
  const FeedbackSection({
    super.key,
    required this.recording,
    this.canManage = false,
  });

  final Recording recording;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(recordingFeedbackProvider(recording.id));
    final player = recordingPlayerControllerProvider(recording.playablePath);
    Future<void> playFrom(Duration position) async {
      await ref.read(player.notifier).seek(position);
      await ref.read(player.notifier).play();
    }

    return switch (notes) {
      AsyncData(value: final notes) when notes.isEmpty => const EmptyState(
        message: AppStrings.noFeedback,
      ),
      AsyncData(value: final notes) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final note in notesInTimeOrder(notes))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spaceS),
              child: FeedbackTile(
                note: note,
                onSeek: playFrom,
                actions: canManage
                    ? NoteActions(recordingId: recording.id, note: note)
                    : null,
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
