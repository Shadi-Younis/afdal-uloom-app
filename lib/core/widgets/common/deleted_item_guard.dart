import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_strings.dart';
import '../islamic/app_top_bar.dart';
import 'app_snack_bar.dart';

/// Leaves a details page whose item is deleted while the page is open, by
/// another device or from another tab of this app: once [item] turns into
/// "does not exist" (data null) after it had data, the page goes back the
/// way the top bar's back button does (the page under it, or its logical
/// parent, AppRoutes.parentOf) and «تم حذف هذا العنصر» is shown.
///
/// It acts only while the page is on screen: a page left in another tab,
/// or under a dialog, waits until it is shown again. A page opened for an
/// item that never existed keeps its not-found state, and nothing happens
/// while [deletingHere] (the page's own delete button shows its own
/// message).
class DeletedItemGuard extends StatefulWidget {
  const DeletedItemGuard({
    super.key,
    required this.item,
    this.deletingHere = false,
    required this.child,
  });

  /// The page's item; data null means it does not exist.
  final AsyncValue<Object?> item;
  final bool deletingHere;
  final Widget child;

  @override
  State<DeletedItemGuard> createState() => _DeletedItemGuardState();
}

class _DeletedItemGuardState extends State<DeletedItemGuard> {
  var _hadItem = false;
  var _leaving = false;

  @override
  void initState() {
    super.initState();
    _remember();
  }

  @override
  void didUpdateWidget(DeletedItemGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _remember();
  }

  void _remember() {
    if (widget.item.value != null) _hadItem = true;
  }

  bool get _gone =>
      _hadItem &&
      widget.item is AsyncData &&
      widget.item.value == null &&
      !widget.deletingHere;

  // Both lookups subscribe this widget, so it rebuilds when the page comes
  // back on screen (its tab is selected again, a dialog closes).
  bool _onScreen(BuildContext context) =>
      TickerMode.valuesOf(context).enabled &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  void _leave() {
    _leaving = false;
    if (!mounted || !_gone || !_onScreen(context)) return;
    final back = AppTopBar.backTarget(context);
    if (back == null) return;
    final messenger = ScaffoldMessenger.of(context);
    back();
    showAppSnackBarOn(messenger, AppStrings.itemDeleted);
  }

  @override
  Widget build(BuildContext context) {
    if (_onScreen(context) && _gone && !_leaving) {
      _leaving = true;
      // Navigating during build is not allowed.
      WidgetsBinding.instance.addPostFrameCallback((_) => _leave());
    }
    return widget.child;
  }
}
