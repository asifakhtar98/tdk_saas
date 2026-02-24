import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/core/monitoring/sentry_service.dart';
import 'package:tkd_brackets/core/router/routes.dart';
import 'package:tkd_brackets/core/router/shell_routes.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_state.dart';

/// Adapts a [Stream] to a [ChangeNotifier] for GoRouter's
/// `refreshListenable`.
///
/// This bridges the BLoC stream to GoRouter so that auth
/// state changes automatically trigger redirect evaluation.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Application router with type-safe routes.
///
/// Uses go_router + go_router_builder for compile-time safety.
/// Auth redirects implemented in Story 2.5.
@lazySingleton
class AppRouter {
  AppRouter();

  final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'root',
  );

  final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  /// The GoRouter instance for this app.
  GoRouter get router => _router;

  late final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: _redirectGuard,
    // refreshListenable triggers redirect re-evaluation
    // when auth state changes
    refreshListenable: GoRouterRefreshStream(
      getIt<AuthenticationBloc>().stream,
    ),
    observers: _buildObservers(),
    routes: [
      // Public routes (no shell)
      $homeRoute,
      $demoRoute,
      // Authenticated routes (with shell)
      createAppShellRoute(
        shellNavigatorKey: _shellNavigatorKey,
        routes: [
          $dashboardRoute,
          $tournamentListRoute,
          $tournamentDetailsRoute,
          $settingsRoute,
        ],
      ),
    ],
    errorBuilder: _buildErrorPage,
  );

  /// Builds the list of navigator observers.
  /// Includes SentryNavigatorObserver when Sentry is
  /// enabled.
  List<NavigatorObserver> _buildObservers() {
    return [if (SentryService.isEnabled) SentryNavigatorObserver()];
  }

  /// Redirect guard with auth state checking.
  String? _redirectGuard(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;

    // Redirect /app routes to dashboard for shell entry
    if (location == '/app' || location == '/app/') {
      return '/dashboard';
    }

    final authState = getIt<AuthenticationBloc>().state;

    // Public routes that don't require auth
    const publicRoutes = ['/', '/demo'];
    final isPublicRoute = publicRoutes.contains(location);

    final isAuthenticated = authState is AuthenticationAuthenticated;

    // If authenticated and on public route, go to
    // dashboard
    if (isAuthenticated && isPublicRoute) {
      return '/dashboard';
    }

    // If not authenticated and on protected route,
    // go home. Don't redirect during initial check.
    if (!isAuthenticated &&
        !isPublicRoute &&
        authState is! AuthenticationCheckInProgress &&
        authState is! AuthenticationInitial) {
      return '/';
    }

    return null;
  }

  /// Error page for unknown routes with accessibility
  /// support.
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
