import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/islamic/app_page_scaffold.dart';
import '../../../core/widgets/islamic/error_state.dart';
import '../application/admin_data_providers.dart';
import 'widgets/account_info.dart';
import 'widgets/admin_async_view.dart';
import 'widgets/content_width.dart';
import 'widgets/disable_account_button.dart';
import 'widgets/edit_profile_button.dart';

/// One admin: account, edit and disable / enable (never one's own account,
/// never the last active admin). Admins cannot be deleted, and only their
/// owner changes their password (from "حسابي").
class AdminDetailsScreen extends ConsumerWidget {
  const AdminDetailsScreen({super.key, required this.adminId});

  final String adminId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref
        .watch(adminAdminsProvider)
        .whenData((all) => all.where((a) => a.id == adminId).firstOrNull);
    return AppPageScaffold(
      title: admin.value?.fullName ?? AppStrings.adminsTitle,
      body: AdminAsyncView(
        value: admin,
        builder: (context, admin) => admin == null
            ? const ErrorState(error: AppException(AppErrorCode.notFound))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                child: ContentWidth(
                  child: AccountInfo(
                    title: AppStrings.adminInfo,
                    user: admin,
                    actions: [
                      EditProfileButton(user: admin),
                      DisableAccountButton(user: admin),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
