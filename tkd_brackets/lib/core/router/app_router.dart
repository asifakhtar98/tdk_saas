import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tkd_brackets/core/monitoring/sentry_service.dart';
import 'package:tkd_brackets/core/router/routes.dart';
import 'package:tkd_brackets/core/router/shell_routes.dart';

/// Application router with type-safe routes.
///
/// Uses go_router + go_router_builder for compile-time safety.
/// Auth redirects implemented in Story 2.5.
@lazySingleton
class AppRouter {
  AppRouter();

  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  /// The GoRouter instance for this app.
  GoRouter get router => _router;

  late final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: _redirectGuard,
    observers: _buildObservers(),
    routes: [
      // Public routes (no shell)
      $homeRoute,
      $demoRoute,
      // Authenticated routes (with shell)
      createAppShellRoute(
        shellNavigatorKey: _shellNavigatorKey,
        routes: [
          $tournamentListRoute,
          $tournamentDetailsRoute,
        ],
      ),
    ],
    errorBuilder: _buildErrorPage,
  );

  /// Builds the list of navigator observers.
  /// Includes SentryNavigatorObserver when Sentry is enabled.
  List<NavigatorObserver> _buildObservers() {
    return [
      if (SentryService.isEnabled) SentryNavigatorObserver(),
    ];
  }

  /// Redirect guard placeholder. Full implementation in Story 2.5.
  String? _redirectGuard(BuildContext context, GoRouterState state) {
    // TODO(story-2.5): Implement auth redirect logic
    return null;
  }

  /// Error page for unknown routes with accessibility support.
  Widget _buildErrorPage(BuildContext context, GoRouterState state) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Page not found error',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                semanticLabel: 'Error icon',
              ),
              const SizedBox(height: 16),
              Text(
                'Page not found: ${state.uri.path}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
