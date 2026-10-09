import 'package:flutter/material.dart';

import '../../constants/app_durations.dart';
import '../../utils/error_messages.dart';

/// Shows [message] in a SnackBar, replacing the one on screen.
void showAppSnackBar(
  BuildContext context,
  String message, {
  Duration duration = AppDurations.snackBar,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: duration));
}

/// Shows the Arabic message for [error] (never its raw text).
void showErrorSnackBar(BuildContext context, Object error) =>
    showAppSnackBar(context, errorMessageOf(error));
