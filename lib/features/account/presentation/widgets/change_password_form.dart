import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/model_limits.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/widgets/common/app_snack_bar.dart';
import '../../../../core/widgets/common/loading_button.dart';
import '../../../../core/widgets/islamic/app_card.dart';
import '../../../../core/widgets/islamic/ornament_divider.dart';
import '../../application/change_password_controller.dart';
import '../../application/change_password_state.dart';
import 'account_password_field.dart';

/// "تغيير كلمة السر" for the signed-in user: current password, new one and
/// its confirmation. On success the fields empty and a SnackBar confirms;
/// the user stays signed in.
class ChangePasswordForm extends ConsumerStatefulWidget {
  const ChangePasswordForm({super.key});

  @override
  ConsumerState<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<ChangePasswordForm> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  ChangePasswordController get _controller =>
      ref.read(changePasswordControllerProvider.notifier);

  @override
  void dispose() {
    for (final c in [_current, _next, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final changed = await _controller.submit(
      current: _current.text,
      next: _next.text,
      confirm: _confirm.text,
    );
    if (!changed || !mounted) return;
    for (final c in [_current, _next, _confirm]) {
      c.clear();
    }
    showAppSnackBar(context, AppStrings.passwordReset);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordControllerProvider);
    final enabled = !state.submitting;
    final theme = Theme.of(context);
    AccountPasswordField field(
      PasswordInput input,
      TextEditingController controller,
      String label,
    ) => AccountPasswordField(
      controller: controller,
      label: label,
      enabled: enabled,
      errorText: passwordProblemText(input, state.problemOf(input)),
      onChanged: () => _controller.edited(input),
    );
    const gap = SizedBox(height: AppSizes.spaceS);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OrnamentDivider(title: AppStrings.resetPassword),
        const SizedBox(height: AppSizes.spaceXS),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.changePasswordHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              gap,
              field(
                PasswordInput.current,
                _current,
                AppStrings.currentPasswordLabel,
              ),
              gap,
              field(PasswordInput.next, _next, AppStrings.newPasswordLabel),
              gap,
              field(
                PasswordInput.confirm,
                _confirm,
                AppStrings.confirmPasswordLabel,
              ),
              if (state.error case final error?) ...[
                gap,
                Text(
                  errorMessageFor(error.code),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSizes.spaceM),
              LoadingButton(
                label: AppStrings.resetPassword,
                icon: Icons.lock_reset,
                loading: state.submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The Arabic text for [problem] under [input], or null when it has none.
String? passwordProblemText(PasswordInput input, PasswordProblem? problem) =>
    switch ((input, problem)) {
      (_, null) => null,
      (PasswordInput.current, PasswordProblem.required) =>
        AppStrings.currentPasswordRequired,
      (_, PasswordProblem.required) => AppStrings.passwordRequired,
      (_, PasswordProblem.length) => AppStrings.passwordLength(
        ModelLimits.passwordMinLength,
        ModelLimits.passwordMaxLength,
      ),
      (_, PasswordProblem.mismatch) => AppStrings.passwordsDontMatch,
      (_, PasswordProblem.wrong) => AppStrings.errorWrongPassword,
      (_, PasswordProblem.weak) => AppStrings.errorWeakPassword,
    };
