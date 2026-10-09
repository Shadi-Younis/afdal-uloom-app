import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_colors.dart';
import '../../application/session_controller.dart';
import '../../constants/app_strings.dart';
import '../../errors/app_exception.dart';
import '../../utils/error_messages.dart';

/// Signs out; the router then goes to the login screen. [onGreen] draws it
/// as the round white-outlined button of the green home header.
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key, this.onGreen = false});

  final bool onGreen;

  static const _circle = 36.0;
  static const _ringAlpha = 0.25;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sessionControllerProvider, (_, next) {
      if (next is AsyncError) {
        final error = next.error;
        final code = error is AppException ? error.code : AppErrorCode.unknown;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessageFor(code))));
      }
    });
    final busy = ref.watch(sessionControllerProvider).isLoading;
    return IconButton(
      icon: onGreen
          ? Container(
              width: _circle,
              height: _circle,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.onGreen.withValues(alpha: _ringAlpha),
                ),
              ),
              child: const Icon(Icons.logout, color: AppColors.onGreen),
            )
          : const Icon(Icons.logout, color: AppColors.green),
      tooltip: AppStrings.logout,
      onPressed: busy
          ? null
          : () => ref.read(sessionControllerProvider.notifier).signOut(),
    );
  }
}
