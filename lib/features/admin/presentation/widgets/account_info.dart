import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_user.dart';
import 'disabled_chip.dart';
import 'info_row.dart';
import 'section_card.dart';

/// The account section of a teacher or student, under [title]: username,
/// [extraRows] (code, halaqa, ...), created date and status, then
/// [actions]. The name is in the page title, so not repeated here.
class AccountInfo extends StatelessWidget {
  const AccountInfo({
    super.key,
    required this.title,
    required this.user,
    required this.actions,
    this.extraRows = const [],
  });

  /// The section title, e.g. "بيانات الطالب" (the page title has the name).
  final String title;
  final AppUser user;
  final List<Widget> extraRows;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final created = MaterialLocalizations.of(context)
        .formatMediumDate(user.createdAt);
    return SectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoRow(
            label: AppStrings.usernameLabel,
            value: user.username,
            ltr: true,
          ),
          ...extraRows,
          InfoRow(label: AppStrings.createdAtLabel, value: created),
          InfoRow(
            label: AppStrings.statusLabel,
            value: AppStrings.statusActive,
            valueWidget: user.disabled ? const DisabledChip() : null,
          ),
          // Full-width buttons, one under the other.
          for (final action in actions) ...[
            const SizedBox(height: AppSizes.spaceS),
            action,
          ],
        ],
      ),
    );
  }
}
