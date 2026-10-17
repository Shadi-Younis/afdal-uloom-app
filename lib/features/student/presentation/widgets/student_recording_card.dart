import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_colors.dart';
import '../../../../core/application/recording_note_counts.dart';
import '../../../../core/application/student_halaqa_provider.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/recording.dart';
import '../../../../core/utils/arabic_digits.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/recording_titles.dart';
import '../../../../core/utils/sheikh_name.dart';
import '../../../../core/widgets/common/recording_type_chip.dart';
import '../../../../core/widgets/common/reviewed_chip.dart';
import '../../../../core/widgets/islamic/app_card.dart';
import '../../../../core/widgets/islamic/surah_cartouche.dart';

/// One recording in the student's list: the surah in a small cartouche
/// («تسجيل» and the date without one), the ayat when given, then the date
/// (and «الشيخ محمود» when the sheikh uploaded it), the type, a gold dot with «ملاحظات جديدة» while notes are unread,
/// how many notes it has, and «تمت المراجعة» once reviewed. A tap opens it
/// (push: back returns to the list).
class StudentRecordingCard extends ConsumerWidget {
  const StudentRecordingCard({super.key, required this.recording});

  final Recording recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = recording;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final notes = ref.watch(recordingNoteCountProvider(r.id)).value ?? 0;
    final ayat = recordingAyatOf(r);
    final halaqa = ref.watch(studentHalaqaProvider).value;
    final sheikh = halaqa != null && halaqa.teacherId == r.uploadedBy
        ? sheikhName(halaqa.teacherName)
        : null;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSizes.spaceS),
      padding: const EdgeInsets.all(AppSizes.spaceS),
      onTap: () => context.push(AppRoutes.recording(r.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SurahCartouche(
            title: recordingHeadingOf(r),
            height: SurahCartouche.compactHeight,
          ),
          if (ayat != null) ...[
            const SizedBox(height: AppSizes.spaceXS),
            Text(
              ayat,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
          ],
          const SizedBox(height: AppSizes.spaceXS),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSizes.spaceS,
            runSpacing: AppSizes.spaceXS,
            children: [
              Text(
                [
                  formatDay(r.recordedAt),
                  ?sheikh,
                ].join(AppStrings.detailSeparator),
                style: muted,
              ),
              RecordingTypeChip(type: r.type),
              if (r.unreadFeedback) const _NewNotes(),
              if (notes > 0)
                Text(
                  AppStrings.markerCount(toArabicDigits(notes)),
                  style: muted,
                ),
              if (r.reviewed)
                const ReviewedChip(
                  reviewed: true,
                  reviewedLabel: AppStrings.reviewedToggle,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A gold dot and «ملاحظات جديدة».
class _NewNotes extends StatelessWidget {
  const _NewNotes();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSizes.unreadDot,
          height: AppSizes.unreadDot,
          decoration: const BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSizes.spaceXS),
        Text(
          AppStrings.newNotes,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.goldDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
