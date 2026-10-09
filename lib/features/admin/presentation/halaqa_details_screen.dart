import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/common/error_view.dart';
import '../application/halaqa_summary.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/admin_page.dart';
import 'widgets/halaqa_details_view.dart';

/// One halaqa: its name, teacher and students, and what the admin can
/// change about it.
class HalaqaDetailsScreen extends ConsumerWidget {
  const HalaqaDetailsScreen({super.key, required this.halaqaId});

  final String halaqaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(halaqaSummaryProvider(halaqaId));
    return AdminPage(
      title: summary.value?.halaqa.name ?? AppStrings.adminNavHalaqat,
      body: AdminAsyncView(
        value: summary,
        builder: (context, summary) => summary == null
            ? const ErrorView(error: AppException(AppErrorCode.notFound))
            : HalaqaDetailsView(summary: summary),
      ),
    );
  }
}
