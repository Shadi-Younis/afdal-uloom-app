import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common/ayah_range_fields.dart';
import '../../../../core/widgets/common/surah_field.dart';
import '../../../../core/widgets/islamic/app_card.dart';
import '../../application/practice_submit_controller.dart';
import 'practice_notice.dart';

/// «ماذا ستتلو؟»: the surah and the ayat, with the same checks as the
/// upload page; «اختر السورة والآيات أولاً» after a send without them.
/// Locked while the practice is being sent.
class PracticeDetailsCard extends ConsumerWidget {
  const PracticeDetailsCard({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(practiceSubmitControllerProvider);
    final controller = ref.read(practiceSubmitControllerProvider.notifier);
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.practiceWhat, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSizes.spaceS),
          SurahField(
            surahNumber: state.surahNumber,
            enabled: enabled,
            onChanged: controller.setSurah,
          ),
          const SizedBox(height: AppSizes.spaceS),
          AyahRangeFields(
            from: state.ayahFrom,
            to: state.ayahTo,
            enabled: enabled,
            error: state.hasInvalidAyat ? AppStrings.ayatNotInSurah : null,
            onFromChanged: controller.setAyahFrom,
            onToChanged: controller.setAyahTo,
          ),
          if (state.showAyatProblem && !state.hasInvalidAyat) ...[
            const SizedBox(height: AppSizes.spaceS),
            PracticeNotice(
              text: AppStrings.completeTheAyat,
              color: theme.colorScheme.error,
              icon: Icons.error_outline,
            ),
          ],
        ],
      ),
    );
  }
}
