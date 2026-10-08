import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common/current_user_name.dart';
import '../../../core/widgets/common/logout_button.dart';

/// The student's home: their name for now, and sign-out.
class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.studentHomeTitle),
        actions: const [LogoutButton()],
      ),
      body: const Center(child: CurrentUserName()),
    );
  }
}
