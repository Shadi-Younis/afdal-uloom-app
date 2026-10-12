import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/picked_audio_file.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/utils/file_size.dart';
import '../../../../core/widgets/islamic/app_card.dart';
import '../../application/practice_submit_controller.dart';
import 'practice_notice.dart';
import 'practice_send_failure.dart';

/// A file picked instead of recording: its name and size, why it cannot be
/// sent (type, size), «إلغاء اختيار الملف» and «إرسال للشيخ» ([onSend]).
class PracticeFileCard extends ConsumerWidget {
  const PracticeFileCard({super.key, required this.file, required this.onSend});

  final PickedAudioFile file;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final problem = ref.watch(practiceSubmitControllerProvider).fileProblem;
    final controller = ref.read(practiceSubmitControllerProvider.notifier);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.audio_file_outlined),
            // A file name is Latin: kept in its own direction.
            title: Text(
              file.name,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(formatFileSize(file.sizeBytes)),
          ),
          if (problem != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spaceS),
              child: PracticeNotice(
                text: errorMessageFor(problem),
                color: theme.colorScheme.error,
                icon: Icons.error_outline,
              ),
            ),
          const PracticeSendFailure(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.clearFile,
                  icon: const Icon(Icons.close),
                  label: const Text(AppStrings.removePickedFile),
                ),
              ),
              const SizedBox(width: AppSizes.spaceS),
              Expanded(
                child: FilledButton.icon(
                  onPressed: problem == null ? onSend : null,
                  icon: const Icon(Icons.send),
                  label: const Text(AppStrings.sendToSheikh),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
