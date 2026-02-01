import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Application router configuration.
// TODO(story-1.3): Implement type-safe routes with go_router_builder.
class AppRouter {
  AppRouter._();

  /// Global router instance.
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('TKD Brackets - Router Placeholder'),
          ),
        ),
      ),
    ],
  );
}
