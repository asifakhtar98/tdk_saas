import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Main application shell that wraps authenticated routes.
/// Provides consistent navigation structure.
/// 
/// Full implementation in Story 1.12 (Foundation UI Shell).
class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TKD Brackets'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: child,
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
    builder: (context, state, child) => AppShellScaffold(child: child),
    routes: routes,
  );
}
