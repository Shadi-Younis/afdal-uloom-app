import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_digits.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/utils/player_format.dart';
import '../../../../core/widgets/islamic/app_card.dart';
import '../../application/practice_recorder_controller.dart';
import '../../application/recorder_phase.dart';
import 'level_meter.dart';
import 'practice_notice.dart';
import 'record_button.dart';

/// The recorder before a take is finished: what it is doing, the length
/// (pauses left out), the live level, the big button (start, pause,
/// resume) and «إنهاء التسجيل»; a warning near the 30-minute limit and
/// the reason when the microphone failed.
class RecorderCard extends ConsumerWidget {
  const RecorderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(practiceRecorderControllerProvider);
    final controller = ref.read(practiceRecorderControllerProvider.notifier);
    final theme = Theme.of(context);
    final phase = state.phase;
    final (status, icon, tooltip, onPressed) = switch (phase) {
      RecorderPhase.recording => (
        AppStrings.recordingNow,
        Icons.pause,
        AppStrings.pauseRecording,
        controller.pause,
      ),
      RecorderPhase.paused => (
        AppStrings.recordingPaused,
        Icons.mic,
        AppStrings.resumeRecording,
        controller.resume,
      ),
      _ => (
        AppStrings.recorderReady,
        Icons.mic,
        AppStrings.startRecording,
        controller.start,
      ),
    };
    final canStop =
        phase == RecorderPhase.recording || phase == RecorderPhase.paused;
    return AppCard(
      child: Column(
        children: [
          _Status(text: status, live: phase == RecorderPhase.recording),
          const SizedBox(height: AppSizes.spaceS),
          Text(
            formatClock(state.elapsed),
            style: AppTextStyles.of(context).statNumber,
          ),
          const SizedBox(height: AppSizes.spaceS),
          LevelMeter(level: state.level),
          const SizedBox(height: AppSizes.spaceL),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RecordButton(
                icon: icon,
                tooltip: tooltip,
                busy:
                    phase == RecorderPhase.starting ||
                    phase == RecorderPhase.stopping,
                onPressed: onPressed,
              ),
              if (phase.isCapturing) ...[
                const SizedBox(width: AppSizes.spaceL),
                SizedBox.square(
                  dimension: AppSizes.recorderSideButton,
                  child: IconButton.outlined(
                    tooltip: AppStrings.stopRecording,
                    onPressed: canStop ? controller.stop : null,
                    icon: const Icon(Icons.stop),
                  ),
                ),
              ],
            ],
          ),
          if (state.nearLimit) ...[
            const SizedBox(height: AppSizes.spaceM),
            PracticeNotice(
              text: AppStrings.recordingNearLimit(
                toArabicDigits(AppDurations.maxPracticeLength.inMinutes),
              ),
              color: AppColors.goldDark,
              icon: Icons.timer_outlined,
            ),
          ],
          if (state.error case final error?) ...[
            const SizedBox(height: AppSizes.spaceM),
            PracticeNotice(
              text: errorMessageOf(error),
              color: theme.colorScheme.error,
              icon: Icons.error_outline,
            ),
          ],
        ],
      ),
    );
  }
}

/// «جارٍ التسجيل» with a red dot while [live], or the other states.
class _Status extends StatelessWidget {
  const _Status({required this.text, required this.live});

  final String text;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (live) ...[
          Container(
            width: AppSizes.unreadDot,
            height: AppSizes.unreadDot,
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSizes.spaceXS),
        ],
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}
