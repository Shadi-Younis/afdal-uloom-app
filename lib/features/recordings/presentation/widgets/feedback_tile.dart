import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/feedback_note.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/player_format.dart';
import '../../../../core/widgets/islamic/app_card.dart';
import '../../application/recording_details_providers.dart';
import 'rating_stars.dart';

/// One teacher note, as a white card with a gold bar on its start side:
/// the teacher and the date, "عند ٠١:٢٣" when it is about a moment of the
/// recording (tapping it calls [onSeek]), the stars when rated, the text.
/// Students see "المعلم" instead of the teacher's name (they may not read
/// teachers' profiles); a deleted teacher shows as "معلم سابق".
class FeedbackTile extends ConsumerWidget {
  const FeedbackTile({super.key, required this.note, required this.onSeek});

  final FeedbackNote note;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final atSecond = note.atSecond;
    final rating = note.rating;
    final author =
        ref.watch(personNameProvider(noteAuthor(note.teacherId))).value ??
        AppStrings.roleTeacher;
    return AppCard(
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSizes.spaceS,
            runSpacing: AppSizes.spaceXS,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '$author${AppStrings.detailSeparator}${formatDay(note.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (atSecond != null)
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.goldTint,
                  side: BorderSide.none,
                  avatar: const Icon(
                    Icons.play_circle_outline,
                    color: AppColors.goldDark,
                  ),
                  label: Text(
                    AppStrings.atTime(formatClock(Duration(seconds: atSecond))),
                  ),
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.goldDark,
                  ),
                  onPressed: () => onSeek(Duration(seconds: atSecond)),
                ),
              if (rating != null) RatingStars(rating: rating),
            ],
          ),
          const SizedBox(height: AppSizes.spaceXS),
          Text(note.note, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
