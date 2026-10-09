import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

/// The "موقوف" marker of a disabled account.
class DisabledChip extends StatelessWidget {
  const DisabledChip({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Chip(
      label: const Text(AppStrings.disabledChip),
      labelStyle: TextStyle(color: colors.onErrorContainer),
      backgroundColor: colors.errorContainer,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
