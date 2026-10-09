import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/error_messages.dart';

/// A form's error that belongs to no field (network, permission, ...), in
/// Arabic. Nothing when [error] is null.
class FormErrorText extends StatelessWidget {
  const FormErrorText(this.error, {super.key});

  final AppException? error;

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    if (error == null) return const SizedBox.shrink();
    return Text(
      errorMessageFor(error.code),
      textAlign: TextAlign.center,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}
