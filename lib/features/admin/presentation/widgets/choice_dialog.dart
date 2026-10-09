import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';

/// One option of [showChoiceDialog].
typedef Choice = ({String id, String label});

/// Lets the admin pick one of [choices]; resolves to its id, or null when
/// dismissed. With no choices it shows [emptyMessage] instead.
Future<String?> showChoiceDialog(
  BuildContext context, {
  required String title,
  required List<Choice> choices,
  required String emptyMessage,
}) => showDialog<String>(
  context: context,
  builder: (context) =>
      ChoiceDialog(title: title, choices: choices, emptyMessage: emptyMessage),
);

/// The dialog of [showChoiceDialog].
class ChoiceDialog extends StatelessWidget {
  const ChoiceDialog({
    super.key,
    required this.title,
    required this.choices,
    required this.emptyMessage,
  });

  final String title;
  final List<Choice> choices;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(title),
      children: [
        if (choices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceL),
            child: Text(emptyMessage),
          ),
        for (final choice in choices)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(choice.id),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spaceL,
              vertical: AppSizes.spaceS,
            ),
            child: Text(choice.label),
          ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceS),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.cancel),
            ),
          ),
        ),
      ],
    );
  }
}
