import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/application/recording_upload_controller.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_digits.dart';
import '../../../../core/widgets/islamic/app_card.dart';
import '../../application/practice_submit_controller.dart';

/// «جارٍ الإرسال»: the progress of the upload, and «إلغاء».
class PracticeSendingCard extends ConsumerWidget {
  const PracticeSendingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = recordingUploadControllerProvider(
      PracticeSubmitController.uploadKey,
    );
    final progress = ref.watch(provider.select((s) => s.progress));
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.saving,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.spaceS),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: AppSizes.spaceXS),
          Text(
            AppStrings.uploading(toArabicDigits((progress * 100).floor())),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.spaceS),
          Center(
            child: TextButton.icon(
              onPressed: () => ref.read(provider.notifier).cancel(),
              icon: const Icon(Icons.close),
              label: const Text(AppStrings.cancel),
            ),
          ),
        ],
      ),
    );
  }
}
