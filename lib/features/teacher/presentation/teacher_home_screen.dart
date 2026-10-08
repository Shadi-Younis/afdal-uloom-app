import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common/current_user_name.dart';
import '../../../core/widgets/common/logout_button.dart';

/// The teacher's home: their name for now, and sign-out.
class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.teacherHomeTitle),
        actions: const [LogoutButton()],
      ),
      body: const Center(child: CurrentUserName()),
    );
  }
}
