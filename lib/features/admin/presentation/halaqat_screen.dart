import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/islamic/empty_state.dart';
import '../application/halaqa_summary.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_page.dart';
import 'widgets/halaqa_tile.dart';

/// Every halaqa with its teacher and number of students.
class HalaqatScreen extends ConsumerWidget {
  const HalaqatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void create() => context.go(AppRoutes.adminNewHalaqa);
    return AdminPage(
      title: AppStrings.adminNavHalaqat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: create,
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.createHalaqa),
      ),
      body: AdminAsyncView(
        value: ref.watch(halaqaSummariesProvider),
        builder: (context, halaqat) => halaqat.isEmpty
            ? EmptyState(
                message: AppStrings.noHalaqat,
                actionLabel: AppStrings.createHalaqa,
                onAction: create,
              )
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: AppSizes.fabClearance),
                itemCount: halaqat.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => HalaqaTile(
                  summary: halaqat[i],
                  onTap: () =>
                      context.go(AppRoutes.adminHalaqa(halaqat[i].halaqa.id)),
                ),
              ),
      ),
    );
  }
}
