import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/lower_case_text_formatter.dart';

/// Username input: left-to-right (usernames are Latin), lower-case, no
/// autocorrect or suggestions.
class UsernameField extends StatelessWidget {
  const UsernameField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      textDirection: TextDirection.ltr,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.username],
      inputFormatters: const [LowerCaseTextFormatter()],
      decoration: const InputDecoration(
        labelText: AppStrings.usernameLabel,
        prefixIcon: Icon(Icons.person_outline),
      ),
      onSubmitted: (_) => onSubmitted(),
    );
  }
}
