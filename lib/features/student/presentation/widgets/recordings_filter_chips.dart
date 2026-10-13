import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../application/recordings_filter.dart';
import '../../application/recordings_filter_controller.dart';

/// «الكل / رسمي / تدريب» above the student's list; one is selected.
class RecordingsFilterChips extends ConsumerWidget {
  const RecordingsFilterChips({super.key});

  static String _label(RecordingsFilter filter) => switch (filter) {
    RecordingsFilter.all => AppStrings.filterAll,
    RecordingsFilter.official => AppStrings.typeOfficial,
    RecordingsFilter.practice => AppStrings.typePractice,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(recordingsFilterProvider);
    return Semantics(
      label: AppStrings.recordingsFilter,
      container: true,
      child: Wrap(
        spacing: AppSizes.spaceS,
        runSpacing: AppSizes.spaceXS,
        children: [
          for (final filter in RecordingsFilter.values)
            ChoiceChip(
              label: Text(_label(filter)),
              selected: filter == selected,
              onSelected: (_) =>
                  ref.read(recordingsFilterProvider.notifier).select(filter),
            ),
        ],
      ),
    );
  }
}
