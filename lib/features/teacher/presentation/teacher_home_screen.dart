import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/session_providers.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common/root_back_scope.dart';
import '../../../core/widgets/islamic/empty_state.dart';
import '../../../core/widgets/islamic/error_state.dart';
import '../../../core/widgets/islamic/home_header.dart';
import '../../../core/widgets/islamic/islamic_pattern_background.dart';

/// The teacher's home: the green header with the Hijri date and greeting,
/// and a placeholder for the features still to come. Android back asks
/// before leaving the app.
class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return RootBackScope(
      child: Scaffold(
        body: IslamicPatternBackground(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HomeHeader(),
              Expanded(
                // hasError, not AsyncError: a provider retrying after an
                // error is loading but still carries it.
                child: user.hasError
                    ? ErrorState(
                        error: user.error!,
                        onRetry: () => ref.invalidate(currentUserProvider),
                      )
                    : const EmptyState(message: AppStrings.teacherComingSoon),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
