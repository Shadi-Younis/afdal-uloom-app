import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/surahs.dart';
import '../../../../core/models/recording.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/common/recording_type_chip.dart';
import '../../../../core/widgets/islamic/surah_cartouche.dart';
import '../../application/recording_details_providers.dart';

/// The surah in its cartouche, then the ayat, the type and the recorded
/// date on one line, and who uploaded it.
class RecordingHeader extends ConsumerWidget {
  const RecordingHeader({super.key, required this.recording});

  final Recording recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = recording;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final uploader = ref.watch(personNameProvider(uploaderOf(r))).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurahCartouche(
          title: AppStrings.surahName(surahByNumber(r.surahNumber).nameAr),
        ),
        const SizedBox(height: AppSizes.spaceS),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSizes.spaceS,
          runSpacing: AppSizes.spaceXS,
          children: [
            Text(formatAyahRange(r.ayahFrom, r.ayahTo), style: muted),
            RecordingTypeChip(type: r.type),
            Text(
              '${AppStrings.recordedAtLabel}: ${formatDay(r.recordedAt)}',
              style: muted,
            ),
          ],
        ),
        if (uploader != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.spaceXS),
            child: Text(
              '${AppStrings.uploadedByLabel}: $uploader',
              textAlign: TextAlign.center,
              style: muted,
            ),
          ),
      ],
    );
  }
}
