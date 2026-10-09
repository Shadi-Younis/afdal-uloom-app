import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_text_styles.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_sizes.dart';
import 'app_back_button.dart';

/// The top bar of every non-home page: a round back button on the start
/// side (when the page can go back), the [title] in Reem Kufi green, and
/// [actions] at the end.
///
/// Back pops the page; a page opened from a link (nothing to pop) goes to
/// its logical parent instead (AppRoutes.parentOf).
class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final back = backTarget(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSizes.spaceS,
        AppSizes.spaceS,
        AppSizes.spaceS,
        AppSizes.spaceXS,
      ),
      child: Row(
        children: [
          if (back != null)
            AppBackButton(onPressed: back)
          else
            const SizedBox(width: AppSizes.spaceS),
          const SizedBox(width: AppSizes.spaceXS),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.of(context).heading,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }

  /// What "back" does on the page of [context], or null on a root page.
  static VoidCallback? backTarget(BuildContext context) {
    // ModalRoute (not Navigator): rebuilds this page when that changes.
    if (ModalRoute.of(context)?.canPop ?? false) {
      return Navigator.of(context).maybePop;
    }
    final location = _location(context);
    final parent = location == null ? null : AppRoutes.parentOf(location);
    if (parent == null) return null;
    return () => context.go(parent);
  }

  /// The page's location, or null outside the router (e.g. a widget test
  /// pumping the page alone).
  static String? _location(BuildContext context) {
    try {
      return GoRouterState.of(context).matchedLocation;
    } on GoError {
      return null;
    }
  }
}
