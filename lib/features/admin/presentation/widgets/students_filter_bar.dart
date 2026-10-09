import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../application/admin_data_providers.dart';
import '../../application/students_filter_controller.dart';

/// The search box and one chip per halaqa above the students list.
class StudentsFilterBar extends ConsumerWidget {
  const StudentsFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(studentsFilterControllerProvider);
    final controller = ref.read(studentsFilterControllerProvider.notifier);
    final halaqat = ref.watch(adminHalaqatProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.spaceS,
            AppSizes.pagePadding,
            0,
          ),
          child: TextField(
            onChanged: controller.setQuery,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: AppStrings.searchStudents,
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.pagePadding,
            vertical: AppSizes.spaceXS,
          ),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text(AppStrings.allHalaqat),
                selected: filter.halaqaId == null,
                onSelected: (_) => controller.setHalaqa(null),
              ),
              for (final halaqa in halaqat) ...[
                const SizedBox(width: AppSizes.spaceXS),
                ChoiceChip(
                  label: Text(halaqa.name),
                  selected: filter.halaqaId == halaqa.id,
                  onSelected: (_) => controller.setHalaqa(halaqa.id),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
