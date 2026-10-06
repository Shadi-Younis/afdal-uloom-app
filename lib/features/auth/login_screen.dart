import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تسجيل الدخول',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            // TODO: remove after auth
            FilledButton(
              onPressed: () => context.go('/admin'),
              child: const Text('دخول كمدير'),
            ),
            const SizedBox(height: 12),
            // TODO: remove after auth
            FilledButton(
              onPressed: () => context.go('/teacher'),
              child: const Text('دخول كمعلم'),
            ),
            const SizedBox(height: 12),
            // TODO: remove after auth
            FilledButton(
              onPressed: () => context.go('/student'),
              child: const Text('دخول كطالب'),
            ),
          ],
        ),
      ),
    );
  }
}
