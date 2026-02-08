import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tkd_brackets/core/router/navigation_items.dart';
import 'package:tkd_brackets/core/widgets/widgets.dart';

/// Main application shell that wraps authenticated routes.
///
/// Provides responsive navigation structure:
/// - Desktop (≥1280px): Extended NavigationRail with toggle
/// - Tablet (768-1279px): Collapsed NavigationRail
/// - Mobile (<768px): Bottom NavigationBar
class AppShellScaffold extends StatefulWidget {
  /// Creates an app shell scaffold.
  const AppShellScaffold({
    required this.child,
    required this.currentLocation,
    super.key,
  });

  /// The child widget to display in the content area.
  final Widget child;

  /// The current route location for navigation state tracking.
  final String currentLocation;

  @override
  State<AppShellScaffold> createState() => _AppShellScaffoldState();
}

class _AppShellScaffoldState extends State<AppShellScaffold> {
  /// Whether the navigation rail is extended (desktop only).
  bool _isRailExtended = true;

  /// Breakpoint for showing bottom navigation (mobile).
  static const double _mobileBreakpoint = 768;

  /// Breakpoint for showing extended navigation rail (desktop).
  static const double _desktopBreakpoint = 1280;

  /// Gets the currently selected navigation index based on route.
  int get _selectedIndex {
    for (var i = 0; i < kNavItems.length; i++) {
      if (widget.currentLocation.startsWith(kNavItems[i].path)) return i;
    }
    return 0; // Default to dashboard
  }

  /// Handles navigation when a destination is selected.
  void _onDestinationSelected(int index) {
    context.go(kNavItems[index].path);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _mobileBreakpoint;
        final isDesktop = constraints.maxWidth >= _desktopBreakpoint;

        return Scaffold(
          appBar: _buildAppBar(context),
          body: isMobile
              ? widget.child
              : Row(
                  children: [
                    _buildNavigationRail(context, isDesktop),
                    Expanded(child: widget.child),
                  ],
                ),
          bottomNavigationBar: isMobile ? _buildBottomNavBar(context) : null,
        );
      },
    );
  }

  /// Builds the app bar with sync status indicator.
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = _getTitleForLocation();

    return AppBar(
      title: Text(title),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      actions: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SyncStatusIndicatorWidget(),
        ),
      ],
    );
  }

  /// Gets the title based on current location.
  String _getTitleForLocation() {
    for (final item in kNavItems) {
      if (widget.currentLocation.startsWith(item.path)) {
        return item.label;
      }
    }
    return 'TKD Brackets';
  }

  /// Builds the navigation rail for tablet/desktop.
  Widget _buildNavigationRail(BuildContext context, bool isDesktop) {
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
      extended: isDesktop && _isRailExtended,
      backgroundColor: colorScheme.surfaceContainerLow,
      indicatorColor: colorScheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
      unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(color: colorScheme.onSurface),
      unselectedLabelTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      trailing: isDesktop ? _buildRailToggle(context) : null,
      destinations: kNavItems.map((item) {
        return NavigationRailDestination(
          icon: Semantics(
            label: '${item.label} navigation',
            child: Icon(item.icon),
          ),
          selectedIcon: Semantics(
            label: '${item.label} navigation, selected',
            child: Icon(item.selectedIcon),
          ),
          label: Text(item.label),
        );
      }).toList(),
    );
  }

  /// Builds the toggle button for extending/collapsing the rail.
  Widget _buildRailToggle(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: IconButton(
            onPressed: () {
              setState(() {
                _isRailExtended = !_isRailExtended;
              });
            },
            icon: Icon(
              _isRailExtended
                  ? Icons.keyboard_double_arrow_left
                  : Icons.keyboard_double_arrow_right,
            ),
            tooltip: _isRailExtended ? 'Collapse menu' : 'Expand menu',
          ),
        ),
      ),
    );
  }

  /// Builds the bottom navigation bar for mobile.
  Widget _buildBottomNavBar(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
      destinations: kNavItems.map((item) {
        return NavigationDestination(
          icon: Semantics(
            label: '${item.label} navigation',
            child: Icon(item.icon),
          ),
          selectedIcon: Semantics(
            label: '${item.label} navigation, selected',
            child: Icon(item.selectedIcon),
          ),
          label: item.label,
        );
      }).toList(),
    );
  }
}

/// Creates shell route configuration for main app scaffold.
ShellRoute createAppShellRoute({
  required GlobalKey<NavigatorState> shellNavigatorKey,
  required List<RouteBase> routes,
}) {
  return ShellRoute(
    navigatorKey: shellNavigatorKey,
    builder: (context, state, child) => AppShellScaffold(
      currentLocation: state.matchedLocation,
      child: child,
    ),
    routes: routes,
  );
}
