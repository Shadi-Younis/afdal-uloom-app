import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_colors.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/playback_source.dart';
import '../../../../core/models/recorded_audio.dart';
import '../../../../core/utils/arabic_digits.dart';
import '../../../../core/utils/player_format.dart';
import '../../../../core/widgets/common/confirm_dialog.dart';
import '../../../../core/widgets/common/recording_player.dart';
import '../../application/practice_recorder_controller.dart';
import 'practice_notice.dart';
import 'practice_send_failure.dart';

/// The finished take: listen to it with the app's player, then
/// «إعادة التسجيل» (after confirming: it is thrown away) or
/// «إرسال للشيخ» ([onSend]).
class PracticeTakeCard extends ConsumerWidget {
  const PracticeTakeCard({
    super.key,
    required this.take,
    required this.length,
    required this.limitReached,
    required this.onSend,
  });

  final RecordedAudio take;
  final Duration length;
  final bool limitReached;
  final VoidCallback onSend;

  Future<void> _recordAgain(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.recordAgain,
      message: AppStrings.recordAgainMessage,
      confirmLabel: AppStrings.recordAgain,
      destructive: true,
    );
    if (confirmed) {
      await ref.read(practiceRecorderControllerProvider.notifier).discard();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${AppStrings.yourRecording}${AppStrings.detailSeparator}'
          '${formatClock(length)}',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSizes.spaceS),
        if (limitReached) ...[
          PracticeNotice(
            text: AppStrings.recordingLimitReached(
              toArabicDigits(AppDurations.maxPracticeLength.inMinutes),
            ),
            color: AppColors.goldDark,
            icon: Icons.timer_outlined,
          ),
          const SizedBox(height: AppSizes.spaceS),
        ],
        RecordingPlayer(source: LocalPlayback(take.playbackUri)),
        const PracticeSendFailure(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _recordAgain(context, ref),
                icon: const Icon(Icons.replay),
                label: const Text(AppStrings.recordAgain),
              ),
            ),
            const SizedBox(width: AppSizes.spaceS),
            Expanded(
              child: FilledButton.icon(
                onPressed: onSend,
                icon: const Icon(Icons.send),
                label: const Text(AppStrings.sendToSheikh),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
