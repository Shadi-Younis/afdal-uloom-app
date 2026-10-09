import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

/// Explains why something cannot be deleted yet ([message]) and what to
/// do first: [links] lead there (each closes the dialog before it runs).
Future<void> showBlockedDeleteDialog(
  BuildContext context, {
  required String title,
  required String message,
  List<({String label, VoidCallback onTap})> links = const [],
  List<({String label, VoidCallback onTap})> actions = const [],
}) => showDialog<void>(
  context: context,
  builder: (context) => BlockedDeleteDialog(
    title: title,
    message: message,
    links: links,
    actions: actions,
  ),
);

/// The dialog of [showBlockedDeleteDialog]: [links] are listed under the
/// message (e.g. the teacher's halaqat), [actions] sit next to "حسناً".
class BlockedDeleteDialog extends StatelessWidget {
  const BlockedDeleteDialog({
    super.key,
    required this.title,
    required this.message,
    this.links = const [],
    this.actions = const [],
  });

  final String title;
  final String message;
  final List<({String label, VoidCallback onTap})> links;
  final List<({String label, VoidCallback onTap})> actions;

  @override
  Widget build(BuildContext context) {
    void closeThen(VoidCallback onTap) {
      Navigator.of(context).pop();
      onTap();
    }

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message),
            for (final link in links)
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: Text(link.label),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: EdgeInsets.zero,
                onTap: () => closeThen(link.onTap),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.ok),
        ),
        for (final action in actions)
          FilledButton(
            onPressed: () => closeThen(action.onTap),
            child: Text(action.label),
          ),
      ],
    );
  }
}
