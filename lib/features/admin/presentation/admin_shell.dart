import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common/root_back_scope.dart';

/// The admin panel's frame around its four sections: a bottom navigation
/// bar on a phone, a navigation rail on wider screens (the studio PC). In
/// the right-to-left layout the rail is on the right.
///
/// Android back on a section's first page goes to the home tab; on the
/// home tab it asks before leaving the app.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const homeIndex = 0;

  /// The four sections, in tab order.
  static const destinations = [
    (
      icon: Icons.home_outlined,
      selected: Icons.home,
      label: AppStrings.adminNavHome,
    ),
    (
      icon: Icons.mosque_outlined,
      selected: Icons.mosque,
      label: AppStrings.adminNavHalaqat,
    ),
    (
      icon: Icons.person_outline,
      selected: Icons.person,
      label: AppStrings.adminNavTeachers,
    ),
    (
      icon: Icons.menu_book_outlined,
      selected: Icons.menu_book,
      label: AppStrings.adminNavStudents,
    ),
  ];

  /// Tapping the current section again goes back to its first page.
  void _select(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  /// Back on a section's first page: to the home tab.
  bool _backToHome() {
    if (navigationShell.currentIndex == homeIndex) return false;
    navigationShell.goBranch(homeIndex);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final wide =
        MediaQuery.sizeOf(context).width >= AppSizes.wideLayoutMinWidth;
    return RootBackScope(
      onBack: _backToHome,
      child: wide
          ? _WideShell(shell: navigationShell, onSelect: _select)
          : _NarrowShell(shell: navigationShell, onSelect: _select),
    );
  }
}

/// Phone: the sections in a bottom navigation bar under a gold hairline.
class _NarrowShell extends StatelessWidget {
  const _NarrowShell({required this.shell, required this.onSelect});

  final StatefulNavigationShell shell;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.goldLight, width: AppSizes.hairline),
        ),
      ),
      child: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: onSelect,
        destinations: [
          for (final d in AdminShell.destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selected),
              label: d.label,
            ),
        ],
      ),
    ),
  );
}

/// Studio PC: the sections in a navigation rail.
class _WideShell extends StatelessWidget {
  const _WideShell({required this.shell, required this.onSelect});

  final StatefulNavigationShell shell;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(
      children: [
        NavigationRail(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: onSelect,
          labelType: NavigationRailLabelType.all,
          destinations: [
            for (final d in AdminShell.destinations)
              NavigationRailDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selected),
                label: Text(d.label),
              ),
          ],
        ),
        const VerticalDivider(
          width: AppSizes.hairline,
          thickness: AppSizes.hairline,
        ),
        Expanded(child: shell),
      ],
    ),
  );
}
