import 'package:flutter/material.dart';

import 'app_top_bar.dart';
import 'islamic_pattern_background.dart';

/// The frame of every page except the homes: ivory with the geometric
/// pattern, [AppTopBar] (back button, title, [actions]) and [body].
///
/// Android back follows the top bar's back button: a page opened from a
/// link, with nothing under it, goes to its logical parent instead of
/// closing the app.
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    // Only a page opened from a link (nothing to pop, but a parent) takes
    // over back; elsewhere back pops, or bubbles up to the home screen's
    // handler on a root page.
    final toParent =
        !(ModalRoute.of(context)?.canPop ?? false) &&
        AppTopBar.backTarget(context) != null;
    return PopScope(
      canPop: !toParent,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) AppTopBar.backTarget(context)?.call();
      },
      child: Scaffold(
        floatingActionButton: floatingActionButton,
        body: IslamicPatternBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTopBar(title: title, actions: actions),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
