import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

/// A password input of the account page, with a show / hide toggle and
/// [errorText] under it.
class AccountPasswordField extends StatefulWidget {
  const AccountPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.enabled,
    required this.errorText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final String? errorText;
  final VoidCallback onChanged;

  @override
  State<AccountPasswordField> createState() => _AccountPasswordFieldState();
}

class _AccountPasswordFieldState extends State<AccountPasswordField> {
  // Purely visual, local state: setState is fine here.
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscured,
      textDirection: TextDirection.ltr,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: (_) => widget.onChanged(),
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        errorMaxLines: 2,
        suffixIcon: IconButton(
          icon: Icon(_obscured ? Icons.visibility : Icons.visibility_off),
          tooltip: _obscured
              ? AppStrings.showPassword
              : AppStrings.hidePassword,
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
    );
  }
}
