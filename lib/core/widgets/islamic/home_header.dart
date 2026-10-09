import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../application/session_providers.dart';
import '../../constants/app_strings.dart';
import '../../providers/clock_provider.dart';
import '../../utils/hijri_date.dart';
import '../common/logout_button.dart';
import 'ornate_header.dart';

/// The top of every role's home: [OrnateHeader] with today's Hijri date
/// and sign-out, "السلام عليكم ورحمة الله" and the user's name.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final styles = AppTextStyles.of(context);
    final textTheme = Theme.of(context).textTheme;
    final today = ref.watch(clockProvider)();
    final name = ref.watch(currentUserProvider).value?.fullName;
    return OrnateHeader(
      top: Row(
        children: [
          Expanded(
            child: Text(
              formatHijriDate(today),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.goldLight),
            ),
          ),
          const LogoutButton(onGreen: true),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.salam, style: styles.salam),
          // Empty while the profile loads, so the header keeps its height.
          Text(
            name ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: styles.headerName,
          ),
        ],
      ),
    );
  }
}
