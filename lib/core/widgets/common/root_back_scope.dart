import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_durations.dart';
import '../../constants/app_strings.dart';
import 'app_snack_bar.dart';

/// Android back on a role's home: [onBack] first (e.g. the admin shell
/// returns to its home tab and reports true). Otherwise the first press
/// shows "اضغط مرة أخرى للخروج" and a second one within
/// [AppDurations.exitConfirmWindow] closes the app.
class RootBackScope extends StatefulWidget {
  const RootBackScope({super.key, required this.child, this.onBack});

  final Widget child;

  /// Returns true when it handled the back press itself.
  final bool Function()? onBack;

  @override
  State<RootBackScope> createState() => _RootBackScopeState();
}

class _RootBackScopeState extends State<RootBackScope> {
  Timer? _armed;

  @override
  void dispose() {
    _armed?.cancel();
    super.dispose();
  }

  void _onBack() {
    if (widget.onBack?.call() ?? false) return;
    if (_armed?.isActive ?? false) {
      SystemNavigator.pop();
      return;
    }
    _armed = Timer(AppDurations.exitConfirmWindow, () {});
    showAppSnackBar(
      context,
      AppStrings.pressBackAgainToExit,
      duration: AppDurations.exitConfirmWindow,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: widget.child,
    );
  }
}
