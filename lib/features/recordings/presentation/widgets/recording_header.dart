import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/surahs.dart';
import '../../../../core/models/recording.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/common/recording_type_chip.dart';
import '../../application/recording_details_providers.dart';

/// Title (surah and ayat), type, recorded date and uploader.
class RecordingHeader extends ConsumerWidget {
  const RecordingHeader({super.key, required this.recording});

  final Recording recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = recording;
    final theme = Theme.of(context);
    final uploader = ref.watch(uploaderNameProvider(r)).value;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spaceM),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatRecordingTitle(r.surahNumber, r.ayahFrom, r.ayahTo),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.spaceS),
            RecordingTypeChip(type: r.type),
            const SizedBox(height: AppSizes.spaceS),
            _DetailLine(
              icon: Icons.event_outlined,
              text: '${AppStrings.recordedAtLabel}: ${formatDay(r.recordedAt)}',
            ),
            if (uploader != null)
              _DetailLine(
                icon: Icons.person_outline,
                text: '${AppStrings.uploadedByLabel}: $uploader',
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceXS),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSizes.spaceS),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
