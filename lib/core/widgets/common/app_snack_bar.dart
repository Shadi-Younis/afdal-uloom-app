import 'package:flutter/material.dart';

import '../../utils/error_messages.dart';

/// Shows [message] in a SnackBar, replacing the one on screen.
void showAppSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Shows the Arabic message for [error] (never its raw text).
void showErrorSnackBar(BuildContext context, Object error) =>
    showAppSnackBar(context, errorMessageOf(error));
