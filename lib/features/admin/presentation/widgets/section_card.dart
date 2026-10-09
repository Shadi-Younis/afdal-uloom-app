import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/islamic/app_card.dart';
import '../../../../core/widgets/islamic/ornament_divider.dart';

/// A titled part of a details page: the title between ornaments, then the
/// content in a card.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrnamentDivider(title: title),
          const SizedBox(height: AppSizes.spaceXS),
          AppCard(child: child),
        ],
      ),
    );
  }
}
