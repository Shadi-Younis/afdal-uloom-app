import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/common/school_logo.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          // Scrolls instead of overflowing on short screens or large text.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SchoolLogo(size: 160),
                const SizedBox(height: 24),
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
        ),
      ),
    );
  }
}
