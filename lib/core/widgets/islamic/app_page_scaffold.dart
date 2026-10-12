import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_top_bar.dart';
import 'islamic_pattern_background.dart';

/// The frame of every page except the homes: ivory with the geometric
/// pattern, [AppTopBar] (back button, title, [actions]) and [body].
///
/// Android back follows the top bar's back button: a page opened from a
/// link, with nothing under it, goes to its logical parent instead of
/// closing the app. With [leaveGuard] both ask it first and stay when it
/// answers false (e.g. an upload is running).
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
    this.leaveGuard,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  /// Asked before leaving by back (top bar or Android); null: leave.
  final Future<bool> Function()? leaveGuard;

  @override
  Widget build(BuildContext context) {
    // Only a page opened from a link (nothing to pop, but a parent) takes
    // over back; elsewhere back pops, or bubbles up to the home screen's
    // handler on a root page.
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final toParent = !canPop && AppTopBar.backTarget(context) != null;
    final guard = leaveGuard;

    // Leaves after the guard agreed: pop (not maybePop, which would ask
    // this PopScope again) or go to the parent.
    Future<void> leave() async {
      if (guard != null && !await guard()) return;
      if (!context.mounted) return;
      final parent = AppTopBar.parentLocation(context);
      if (ModalRoute.of(context)?.canPop ?? false) {
        Navigator.of(context).pop();
      } else if (parent != null) {
        context.go(parent);
      }
    }

    return PopScope(
      canPop: !toParent && guard == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) leave();
      },
      child: Scaffold(
        floatingActionButton: floatingActionButton,
        body: IslamicPatternBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTopBar(
                  title: title,
                  actions: actions,
                  onBack: guard == null ? null : leave,
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
