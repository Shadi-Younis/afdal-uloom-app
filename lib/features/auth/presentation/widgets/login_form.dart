import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../application/login_controller.dart';
import 'login_error_text.dart';
import 'login_submit_button.dart';
import 'password_field.dart';
import 'username_field.dart';

/// Username, password, the sign-in button and the error text under them.
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    ref
        .read(loginControllerProvider.notifier)
        .signIn(_username.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final loading = state.isLoading;
    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          UsernameField(
            controller: _username,
            enabled: !loading,
            onSubmitted: _passwordFocus.requestFocus,
          ),
          const SizedBox(height: AppSizes.spaceS),
          PasswordField(
            controller: _password,
            focusNode: _passwordFocus,
            enabled: !loading,
            onSubmitted: _submit,
          ),
          const SizedBox(height: AppSizes.spaceL),
          LoginSubmitButton(loading: loading, onPressed: _submit),
          if (state case AsyncError(:final error) when !loading) ...[
            const SizedBox(height: AppSizes.spaceS),
            LoginErrorText(error),
          ],
        ],
      ),
    );
  }
}
