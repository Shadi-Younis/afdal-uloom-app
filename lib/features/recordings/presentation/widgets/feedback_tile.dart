import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/feedback_note.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/player_format.dart';
import 'rating_stars.dart';

/// One teacher note: its text, the stars when rated, and "عند ٠١:٢٣" when
/// it is about a moment of the recording (tapping it calls [onSeek]).
class FeedbackTile extends StatelessWidget {
  const FeedbackTile({super.key, required this.note, required this.onSeek});

  final FeedbackNote note;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final atSecond = note.atSecond;
    final rating = note.rating;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.note, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSizes.spaceXS),
          Wrap(
            spacing: AppSizes.spaceS,
            runSpacing: AppSizes.spaceXS,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (atSecond != null)
                ActionChip(
                  avatar: const Icon(Icons.play_circle_outline),
                  label: Text(
                    AppStrings.atTime(formatClock(Duration(seconds: atSecond))),
                  ),
                  onPressed: () => onSeek(Duration(seconds: atSecond)),
                ),
              if (rating != null) RatingStars(rating: rating),
              Text(
                formatDay(note.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
