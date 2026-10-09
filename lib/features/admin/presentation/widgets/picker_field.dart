import 'package:flutter/material.dart';

import 'choice_dialog.dart';

/// A dropdown of [choices] (a halaqa, a teacher) inside a form.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.choices,
    required this.enabled,
    required this.errorText,
    required this.onChanged,
  });

  final String label;

  /// The chosen id, or null.
  final String? value;
  final List<Choice> choices;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      items: [
        for (final c in choices)
          DropdownMenuItem(value: c.id, child: Text(c.label)),
      ],
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(labelText: label, errorText: errorText),
    );
  }
}
