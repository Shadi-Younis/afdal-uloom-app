import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

/// Password input with a show / hide toggle. Submits on the keyboard's
/// "done" action.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  // Purely visual, local state: setState is fine here.
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      obscureText: _obscured,
      textDirection: TextDirection.ltr,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      decoration: InputDecoration(
        labelText: AppStrings.passwordLabel,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_obscured ? Icons.visibility : Icons.visibility_off),
          tooltip: _obscured
              ? AppStrings.showPassword
              : AppStrings.hidePassword,
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
      onSubmitted: (_) => widget.onSubmitted(),
    );
  }
}
