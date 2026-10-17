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

/// One note, as a white card with a gold bar on its start side.
///
/// A voice marker (the sheikh spoke there): «ملاحظة صوتية من الشيخ ·
/// ٠١:٢٣–٠١:٣١», then the text the teacher added, if any; tapping the card
/// plays from there ([onSeek]). A written note: the teacher and the date,
/// "عند ٠١:٢٣" when it is about a moment (tapping it calls [onSeek]), the
/// text. Students see "المعلم" instead of the
/// teacher's name (they may not read teachers' profiles); a deleted
/// teacher shows as "معلم سابق". [actions] (edit, delete) go at the end of
/// the first line.
class FeedbackTile extends ConsumerWidget {
  const FeedbackTile({
    super.key,
    required this.note,
    required this.onSeek,
    this.actions,
  });

  final FeedbackNote note;
  final ValueChanged<Duration> onSeek;
  final Widget? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final atSecond = note.atSecond;
    final header = note.isVoice
        ? _VoiceHeader(note: note)
        : _TextHeader(note: note, onSeek: onSeek);
    return AppCard(
      accent: true,
      onTap: note.isVoice && atSecond != null
          ? () => onSeek(Duration(seconds: atSecond))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: header),
              ?actions,
            ],
          ),
          if (note.note.isNotEmpty) ...[
            const SizedBox(height: AppSizes.spaceXS),
            Text(note.note, style: theme.textTheme.bodyLarge),
          ],
        ],
      ),
    );
  }
}

/// «ملاحظة صوتية من الشيخ · ٠١:٢٣–٠١:٣١».
class _VoiceHeader extends StatelessWidget {
  const _VoiceHeader({required this.note});

  final FeedbackNote note;

  @override
  Widget build(BuildContext context) {
    final start = Duration(seconds: note.atSecond ?? 0);
    final end = note.endSecond;
    final time = end == null
        ? formatClock(start)
        : AppStrings.timeRange(
            formatClock(start),
            formatClock(Duration(seconds: end)),
          );
    final style = Theme.of(context).textTheme.labelLarge
        ?.copyWith(color: AppColors.goldDark);
    // Two pieces that never break inside: on a phone the time moves to
    // the next line as a whole instead of splitting the range.
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsetsDirectional.only(end: AppSizes.spaceXS),
          child: Icon(
            Icons.record_voice_over_outlined,
            color: AppColors.goldDark,
          ),
        ),
        Text(AppStrings.voiceNote, style: style),
        Text('${AppStrings.detailSeparator}$time', style: style),
      ],
    );
  }
}

/// The teacher and the date, and "عند ٠١:٢٣".
class _TextHeader extends ConsumerWidget {
  const _TextHeader({required this.note, required this.onSeek});

  final FeedbackNote note;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final atSecond = note.atSecond;
    final author =
        ref.watch(personNameProvider(noteAuthor(note.teacherId))).value ??
        AppStrings.roleTeacher;
    return Wrap(
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
      ],
    );
  }
}
