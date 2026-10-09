import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_user.dart';
import 'disabled_chip.dart';
import 'info_row.dart';
import 'section_card.dart';

/// The account card of a teacher or student: name, username, [extraRows]
/// (code, halaqa, ...), created date and status, then [actions].
class AccountInfo extends StatelessWidget {
  const AccountInfo({
    super.key,
    required this.user,
    required this.actions,
    this.extraRows = const [],
  });

  final AppUser user;
  final List<Widget> extraRows;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final created = MaterialLocalizations.of(context)
        .formatMediumDate(user.createdAt);
    return SectionCard(
      title: user.fullName,
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
