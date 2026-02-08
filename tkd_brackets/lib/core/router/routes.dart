import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tkd_brackets/features/dashboard/dashboard.dart';
import 'package:tkd_brackets/features/demo/presentation/pages/demo_page.dart';
import 'package:tkd_brackets/features/home/presentation/pages/home_page.dart';
import 'package:tkd_brackets/features/settings/settings.dart';
import 'package:tkd_brackets/features/tournament/tournament.dart';

part 'routes.g.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Core Routes (Permanent)
// ═══════════════════════════════════════════════════════════════════════════

/// Home route - landing page after app launch.
@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

/// Demo route - explore app without account.
@TypedGoRoute<DemoRoute>(path: '/demo')
class DemoRoute extends GoRouteData {
  const DemoRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const DemoPage();
}

// ═══════════════════════════════════════════════════════════════════════════
// Shell Routes (Inside AppShellScaffold)
// ═══════════════════════════════════════════════════════════════════════════

/// Dashboard route - main app landing page within shell.
@TypedGoRoute<DashboardRoute>(path: '/dashboard')
class DashboardRoute extends GoRouteData {
  const DashboardRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DashboardPage();
}

/// Settings route - app configuration.
@TypedGoRoute<SettingsRoute>(path: '/settings')
class SettingsRoute extends GoRouteData {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsPage();
}

/// Tournament list route - placeholder for Epic 3.
@TypedGoRoute<TournamentListRoute>(path: '/tournaments')
class TournamentListRoute extends GoRouteData {
  const TournamentListRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const TournamentListPage();
}

/// Tournament details route - demonstrates route parameters.
@TypedGoRoute<TournamentDetailsRoute>(path: '/tournaments/:tournamentId')
class TournamentDetailsRoute extends GoRouteData {
  const TournamentDetailsRoute({required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context, GoRouterState state) => Scaffold(
        appBar: AppBar(title: Text('Tournament $tournamentId')),
        body: Center(
          child: Text('Tournament Details: $tournamentId'),
        ),
      );
}
