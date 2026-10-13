import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/application/session_providers.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common/content_width.dart';
import '../../../core/widgets/common/root_back_scope.dart';
import '../../../core/widgets/islamic/error_state.dart';
import '../../../core/widgets/islamic/home_header.dart';
import '../../../core/widgets/islamic/islamic_pattern_background.dart';
import '../../../core/widgets/islamic/ornament_divider.dart';
import '../../../core/widgets/islamic/ornate_header.dart';
import 'widgets/recordings_filter_chips.dart';
import 'widgets/student_overview_cards.dart';
import 'widgets/student_recordings_list.dart';

/// The student's home: the green header with the Hijri date, greeting and
/// «حسابي», his three counts overlapping it, «سجّل تدريباً», then
/// «تسجيلاتي» with the «الكل / رسمي / تدريب» chips and the list, newest
/// first and live. Android back asks before leaving the app.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return RootBackScope(
      child: Scaffold(
        body: IslamicPatternBackground(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HomeHeader(),
                // The counts overlap the header's bottom, as in the design.
                Transform.translate(
                  offset: const Offset(0, -OrnateHeader.overlap),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.pagePadding,
                    ),
                    child: ContentWidth(
                      // hasError, not AsyncError: a provider retrying after
                      // an error is loading but still carries it.
                      child: user.hasError
                          ? ErrorState(
                              error: user.error!,
                              onRetry: () =>
                                  ref.invalidate(currentUserProvider),
                            )
                          : const _StudentHomeContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentHomeContent extends StatelessWidget {
  const _StudentHomeContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StudentOverviewCards(),
        const SizedBox(height: AppSizes.spaceM),
        SizedBox(
          height: AppSizes.buttonHeight,
          child: FilledButton.icon(
            onPressed: () => context.push(AppRoutes.studentPractice),
            icon: const Icon(Icons.mic_none),
            label: const Text(AppStrings.recordPractice),
          ),
        ),
        const SizedBox(height: AppSizes.spaceS),
        const OrnamentDivider(title: AppStrings.myRecordings),
        const SizedBox(height: AppSizes.spaceXS),
        const RecordingsFilterChips(),
        const SizedBox(height: AppSizes.spaceS),
        const StudentRecordingsList(),
      ],
    );
  }
}
