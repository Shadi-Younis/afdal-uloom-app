import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/lower_case_text_formatter.dart';

/// A new account's username: left to right, lower-cased as typed.
class UsernameInput extends StatelessWidget {
  const UsernameInput({
    super.key,
    required this.controller,
    required this.enabled,
    required this.errorText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? errorText;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      textDirection: TextDirection.ltr,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: const [LowerCaseTextFormatter()],
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: AppStrings.usernameLabel,
        errorText: errorText,
      ),
    );
  }
}
