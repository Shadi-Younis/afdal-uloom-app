import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المعلم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            // TODO: replace with real signOut (phase 2.4)
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'لوحة المعلم',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
