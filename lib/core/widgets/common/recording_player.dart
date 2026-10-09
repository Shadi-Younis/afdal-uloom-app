import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/recording_player_controller.dart';
import '../../application/recording_player_phase.dart';
import '../../constants/app_durations.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../islamic/error_state.dart';
import 'playback_speed_selector.dart';
import 'player_controls.dart';
import 'player_seek_bar.dart';

/// Plays the recording stored at [storagePath]: seek bar with times,
/// back / play-pause / forward, and the speed. Shows loading and Arabic
/// errors (with retry). Stops when it leaves the screen.
///
/// To seek from outside (e.g. a note's "at ٠١:٢٣"), or to read the current
/// position, use `recordingPlayerControllerProvider(storagePath)`.
class RecordingPlayer extends ConsumerWidget {
  const RecordingPlayer({super.key, required this.storagePath});

  final String storagePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = recordingPlayerControllerProvider(storagePath);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spaceM),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceM),
        child: switch (state.phase) {
          RecordingPlayerPhase.loading => const _PlayerLoading(),
          RecordingPlayerPhase.error => ErrorState(
            error: state.error!,
            onRetry: controller.retry,
          ),
          RecordingPlayerPhase.ready => Column(
            children: [
              PlayerSeekBar(
                position: state.position,
                duration: state.duration,
                onSeek: controller.seek,
              ),
              const SizedBox(height: AppSizes.spaceS),
              PlayerControls(
                playing: state.playing,
                buffering: state.buffering,
                onTogglePlay: controller.togglePlay,
                onSkipBack: () => controller.skip(-AppDurations.playerSkip),
                onSkipForward: () => controller.skip(AppDurations.playerSkip),
              ),
              const SizedBox(height: AppSizes.spaceS),
              PlaybackSpeedSelector(
                speed: state.speed,
                onChanged: controller.setSpeed,
              ),
            ],
          ),
        },
      ),
    );
  }
}

class _PlayerLoading extends StatelessWidget {
  const _PlayerLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.spaceL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(semanticsLabel: AppStrings.playerLoading),
          SizedBox(height: AppSizes.spaceS),
          Text(AppStrings.playerLoading),
        ],
      ),
    );
  }
}
