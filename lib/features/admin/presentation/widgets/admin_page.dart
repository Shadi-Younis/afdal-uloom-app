import 'package:flutter/material.dart';

import '../../../../core/widgets/common/logout_button.dart';

/// The frame of every admin page: an app bar with [title] and the logout
/// action. Sub-pages get a back button from the app bar automatically.
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: const [LogoutButton()]),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
