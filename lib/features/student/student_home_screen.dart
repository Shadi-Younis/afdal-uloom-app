import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الطالب'),
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
          'لوحة الطالب',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
