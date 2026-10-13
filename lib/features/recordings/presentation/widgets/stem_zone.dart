import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/picked_audio_file.dart';
import '../../../../core/models/stem_role.dart';
import '../../../../core/utils/file_size.dart';
import '../../../../core/utils/player_format.dart';
import 'upload_drop_area.dart';

/// One file of a two-file recording: «صوت الطالب» or «صوت الشيخ», its
/// name, size and length (when known), and «اختيار ملف». On the web files
/// can be dropped on it ([hovering] while they are over it).
class StemZone extends StatelessWidget {
  const StemZone({
    super.key,
    required this.role,
    required this.file,
    required this.duration,
    required this.hovering,
    required this.onPick,
  });

  final StemRole role;
  final PickedAudioFile? file;
  final Duration? duration;
  final bool hovering;

  /// Null while the row cannot be edited.
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final file = this.file;
    final size = file == null ? null : formatFileSize(file.sizeBytes);
    final duration = this.duration;
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceS),
      decoration: BoxDecoration(
        color: hovering ? AppColors.goldTint : AppColors.ivory,
        border: Border.all(
          color: hovering || file != null ? AppColors.gold : AppColors.track,
          width: hovering ? AppSizes.focusBorder : AppSizes.hairline,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusField),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                role == StemRole.student
                    ? Icons.person_outline
                    : Icons.record_voice_over_outlined,
                color: AppColors.goldDark,
              ),
              const SizedBox(width: AppSizes.spaceXS),
              Expanded(
                child: Text(
                  role == StemRole.student
                      ? AppStrings.stemStudent
                      : AppStrings.stemSheikh,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceXS),
          if (file == null)
            Text(
              UploadDropArea.supported
                  ? AppStrings.dropStem
                  : AppStrings.noStemYet,
              style: muted,
            )
          else ...[
            // File names are Latin: keep them left-to-right.
            Text(
              file.name,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              duration == null
                  ? size!
                  : AppStrings.sizeAndLength(size!, formatClock(duration)),
              style: muted,
            ),
          ],
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text(AppStrings.pickStem),
            ),
          ),
        ],
      ),
    );
  }
}
