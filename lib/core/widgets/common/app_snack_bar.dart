import 'package:flutter/material.dart';

import '../../constants/app_durations.dart';
import '../../utils/error_messages.dart';

/// Shows [message] in a SnackBar, replacing the one on screen.
void showAppSnackBar(
  BuildContext context,
  String message, {
  Duration duration = AppDurations.snackBar,
}) => showAppSnackBarOn(
  ScaffoldMessenger.of(context),
  message,
  duration: duration,
);

/// [showAppSnackBar] on a [messenger] looked up earlier: for a message
/// after the page that asked for it is gone (e.g. it was deleted).
void showAppSnackBarOn(
  ScaffoldMessengerState messenger,
  String message, {
  Duration duration = AppDurations.snackBar,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: duration));
}

/// Shows the Arabic message for [error] (never its raw text).
void showErrorSnackBar(BuildContext context, Object error) =>
    showAppSnackBar(context, errorMessageOf(error));
