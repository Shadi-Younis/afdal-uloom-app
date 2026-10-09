import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/widgets/common/app_snack_bar.dart';
import '../../../../core/widgets/common/confirm_dialog.dart';
import '../../../../core/widgets/common/loading_button.dart';
import '../../application/admin_data_providers.dart';
import '../../application/set_user_disabled_controller.dart';

/// "إيقاف الحساب" or "إعادة تفعيل الحساب" for [user], after a
/// confirmation. Hidden on the admin's own account.
class DisableAccountButton extends ConsumerWidget {
  const DisableAccountButton({super.key, required this.user});

  final AppUser user;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final disable = !user.disabled;
    final label = disable
        ? AppStrings.disableAccount
        : AppStrings.enableAccount;
    final confirmed = await showConfirmDialog(
      context,
      title: label,
      message: disable
          ? AppStrings.disableConfirm(user.fullName)
          : AppStrings.enableConfirm(user.fullName),
      confirmLabel: label,
    );
    if (!confirmed || !context.mounted) return;
    final done = await ref
        .read(setUserDisabledControllerProvider(user.id).notifier)
        .setDisabled(disable);
    if (done && context.mounted) {
      showAppSnackBar(
        context,
        disable ? AppStrings.accountDisabled : AppStrings.accountEnabled,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(canDisableProvider(user.id))) return const SizedBox.shrink();
    final provider = setUserDisabledControllerProvider(user.id);
    ref.listen(provider, (_, next) {
      if (next case AsyncError(:final error)) showErrorSnackBar(context, error);
    });
    return LoadingButton(
      filled: false,
      label: user.disabled
          ? AppStrings.enableAccount
          : AppStrings.disableAccount,
      icon: user.disabled ? Icons.check_circle_outline : Icons.block,
      loading: ref.watch(provider).isLoading,
      onPressed: () => _toggle(context, ref),
    );
  }
}
