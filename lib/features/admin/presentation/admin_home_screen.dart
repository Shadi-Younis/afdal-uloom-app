import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common/current_user_name.dart';
import '../../../core/widgets/common/logout_button.dart';

/// The admin's home: their name for now, and sign-out.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.adminHomeTitle),
        actions: const [LogoutButton()],
      ),
      body: const Center(child: CurrentUserName()),
    );
  }
}
