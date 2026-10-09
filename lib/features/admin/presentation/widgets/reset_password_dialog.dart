import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/widgets/common/loading_button.dart';
import '../../application/input_field.dart';
import '../../application/reset_password_controller.dart';
import 'form_error_text.dart';
import 'input_error_text.dart';
import 'password_input.dart';

/// Sets a new password for [user]: a generated one, editable. Pops with the
/// IssuedCredentials on success. Cannot be closed while the call runs, so
/// a password that was set is never lost.
class ResetPasswordDialog extends ConsumerStatefulWidget {
  const ResetPasswordDialog({super.key, required this.user});

  final AppUser user;

  @override
  ConsumerState<ResetPasswordDialog> createState() =>
      _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends ConsumerState<ResetPasswordDialog> {
  final _password = TextEditingController();

  ResetPasswordController get _controller =>
      ref.read(resetPasswordControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _password.text = _controller.suggestPassword();
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final credentials = await _controller.reset(widget.user, _password.text);
    if (credentials != null && mounted) Navigator.of(context).pop(credentials);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordControllerProvider);
    return PopScope(
      canPop: !state.submitting,
      child: AlertDialog(
        title: Text(AppStrings.resetPasswordTitle(widget.user.fullName)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PasswordInput(
              controller: _password,
              enabled: !state.submitting,
              errorText: inputErrorText(state, InputField.password),
              onRegenerate: () {
                _password.text = _controller.suggestPassword();
                _controller.edited(InputField.password);
              },
              onChanged: () => _controller.edited(InputField.password),
            ),
            if (state.error != null) ...[
              const SizedBox(height: AppSizes.spaceS),
              FormErrorText(state.error),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: state.submitting
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          LoadingButton(
            label: AppStrings.save,
            loading: state.submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
