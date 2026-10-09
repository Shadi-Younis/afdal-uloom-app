import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

/// A new password for someone else: shown in clear (the admin passes it
/// on), editable, with a button that generates another one.
class PasswordInput extends StatelessWidget {
  const PasswordInput({
    super.key,
    required this.controller,
    required this.enabled,
    required this.errorText,
    required this.onRegenerate,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? errorText;
  final VoidCallback onRegenerate;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      textDirection: TextDirection.ltr,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: AppStrings.passwordLabel,
        errorText: errorText,
        prefixIcon: const Icon(Icons.key_outlined),
        suffixIcon: IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: AppStrings.generatePassword,
          onPressed: enabled ? onRegenerate : null,
        ),
      ),
    );
  }
}
