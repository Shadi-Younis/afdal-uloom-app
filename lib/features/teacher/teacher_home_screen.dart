import 'package:flutter/material.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'لوحة المعلم',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
