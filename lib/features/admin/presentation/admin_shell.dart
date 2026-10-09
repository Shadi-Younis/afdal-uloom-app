import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// The admin panel's frame around its four sections: a bottom navigation
/// bar on a phone, a navigation rail on wider screens (the studio PC). In
/// the right-to-left layout the rail is on the right.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (
      icon: Icons.home_outlined,
      selected: Icons.home,
      label: AppStrings.adminNavHome,
    ),
    (
      icon: Icons.groups_outlined,
      selected: Icons.groups,
      label: AppStrings.adminNavHalaqat,
    ),
    (
      icon: Icons.person_outline,
      selected: Icons.person,
      label: AppStrings.adminNavTeachers,
    ),
    (
      icon: Icons.school_outlined,
      selected: Icons.school,
      label: AppStrings.adminNavStudents,
    ),
  ];

  /// Tapping the current section again goes back to its first page.
  void _select(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final wide =
        MediaQuery.sizeOf(context).width >= AppSizes.wideLayoutMinWidth;
    if (!wide) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _select,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selected),
                label: d.label,
              ),
          ],
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _select,
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selected),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
