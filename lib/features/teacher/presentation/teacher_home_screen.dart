import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common/content_width.dart';
import '../../../core/widgets/common/root_back_scope.dart';
import '../../../core/widgets/islamic/home_header.dart';
import '../../../core/widgets/islamic/islamic_pattern_background.dart';
import '../../../core/widgets/islamic/ornament_divider.dart';
import '../../../core/widgets/islamic/ornate_header.dart';
import '../../../core/widgets/islamic/todays_hadith_card.dart';
import 'widgets/teacher_halaqat_list.dart';
import 'widgets/teacher_overview_cards.dart';

/// The teacher's home: the green header with the Hijri date and greeting,
/// «حديث اليوم» overlapping it, the three counts, «رفع تسجيلات», and «حلقاتي». Android
/// back asks before leaving the app.
class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const TodaysHadithCard(),
                          const SizedBox(height: AppSizes.spaceM),
                          const TeacherOverviewCards(),
                          const SizedBox(height: AppSizes.spaceM),
                          FilledButton.icon(
                            onPressed: () =>
                                context.push(AppRoutes.teacherUpload()),
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text(AppStrings.uploadRecordings),
                          ),
                          const SizedBox(height: AppSizes.spaceS),
                          const OrnamentDivider(title: AppStrings.myHalaqat),
                          const SizedBox(height: AppSizes.spaceXS),
                          const TeacherHalaqatList(),
                        ],
                      ),
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
