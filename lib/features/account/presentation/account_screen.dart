import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/session_providers.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/islamic/app_page_scaffold.dart';
import '../../../core/widgets/islamic/error_state.dart';
import '../../../core/widgets/islamic/loading_state.dart';
import 'widgets/change_password_form.dart';
import 'widgets/my_info_card.dart';

/// "حسابي", for every role: the signed-in user's name, username and role,
/// and changing their own password.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return AppPageScaffold(
      title: AppStrings.myAccount,
      body: switch (user) {
        AsyncData(value: final user?) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MyInfoCard(user: user),
                  const SizedBox(height: AppSizes.spaceM),
                  const ChangePasswordForm(),
                ],
              ),
            ),
          ),
        ),
        AsyncError(:final error) when !user.hasValue => ErrorState(
          error: error,
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
        // Loading, or signed out a moment before the router leaves.
        _ => const LoadingState(),
      },
    );
  }
}
