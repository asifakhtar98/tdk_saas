import 'package:flutter/material.dart';

/// Navigation destination definition for app shell.
///
/// Defines a navigation item with path, label, and icon variants
/// used by both NavigationRail and NavigationBar.
class NavItem {
  /// Creates a navigation item.
  const NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  /// The route path for this navigation item.
  final String path;

  /// The display label for this navigation item.
  final String label;

  /// The icon to display when this item is not selected.
  final IconData icon;

  /// The icon to display when this item is selected.
  final IconData selectedIcon;
}

/// App navigation items - shared between shell and tests.
///
/// Defines the main navigation destinations in the app.
/// Order matters - index is used for selection tracking.
const kNavItems = [
  NavItem(
    path: '/dashboard',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  NavItem(
    path: '/tournaments',
    label: 'Tournaments',
    icon: Icons.emoji_events_outlined,
    selectedIcon: Icons.emoji_events,
  ),
  NavItem(
    path: '/settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  ),
];
