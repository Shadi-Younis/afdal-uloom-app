import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/islamic/app_card.dart';
import '../../application/practice_recorder_controller.dart';

/// The microphone was refused: how to allow it, «فتح الإعدادات» on the
/// phone (the browser has no such page: its site settings are explained
/// instead), and «إعادة المحاولة».
class MicrophoneDeniedCard extends ConsumerWidget {
  const MicrophoneDeniedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(practiceRecorderControllerProvider.notifier);
    return AppCard(
      child: Column(
        children: [
          Icon(
            Icons.mic_off_outlined,
            size: AppSizes.emptyIcon,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: AppSizes.spaceS),
          Text(
            kIsWeb
                ? AppStrings.microphoneDeniedWeb
                : AppStrings.microphoneDenied,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSizes.spaceM),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSizes.spaceS,
            runSpacing: AppSizes.spaceS,
            children: [
              if (!kIsWeb)
                FilledButton.icon(
                  onPressed: controller.openSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text(AppStrings.openSettings),
                ),
              OutlinedButton.icon(
                onPressed: controller.start,
                icon: const Icon(Icons.refresh),
                label: const Text(AppStrings.retry),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
