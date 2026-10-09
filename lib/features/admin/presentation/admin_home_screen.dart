import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/islamic/home_header.dart';
import '../../../core/widgets/islamic/islamic_pattern_background.dart';
import '../../../core/widgets/islamic/ornament_divider.dart';
import '../../../core/widgets/islamic/ornate_header.dart';
import 'widgets/content_width.dart';
import 'widgets/home_shortcuts.dart';
import 'widgets/overview_cards.dart';

/// The admin's home: the green header with the Hijri date and greeting,
/// the school's counts overlapping it, and shortcuts to the most common
/// tasks.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IslamicPatternBackground(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HomeHeader(),
              // The counts overlap the header's bottom, as in the design.
              Transform.translate(
                offset: const Offset(0, -OrnateHeader.bottomPadding),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.pagePadding,
                  ),
                  child: ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OverviewCards(),
                        SizedBox(height: AppSizes.spaceS),
                        OrnamentDivider(title: AppStrings.shortcutsTitle),
                        SizedBox(height: AppSizes.spaceXS),
                        HomeShortcuts(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
