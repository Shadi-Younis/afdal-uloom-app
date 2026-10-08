import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/session_controller.dart';
import '../../constants/app_strings.dart';
import '../../errors/app_exception.dart';
import '../../utils/error_messages.dart';

/// App bar action that signs out. The router then goes to the login screen.
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

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
      icon: const Icon(Icons.logout),
      tooltip: AppStrings.logout,
      onPressed: busy
          ? null
          : () => ref.read(sessionControllerProvider.notifier).signOut(),
    );
  }
}
