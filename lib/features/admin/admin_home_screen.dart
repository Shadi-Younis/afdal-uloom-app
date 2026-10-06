import 'package:flutter/material.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'لوحة المدير',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
