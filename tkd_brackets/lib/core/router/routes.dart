import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tkd_brackets/features/dashboard/dashboard.dart';
import 'package:tkd_brackets/features/demo/presentation/pages/demo_page.dart';
import 'package:tkd_brackets/features/home/presentation/pages/home_page.dart';
import 'package:tkd_brackets/features/participant/presentation/pages/csv_import_page.dart';
import 'package:tkd_brackets/features/participant/presentation/pages/participant_list_page.dart';
import 'package:tkd_brackets/features/auth/presentation/pages/user_settings_page.dart';
import 'package:tkd_brackets/features/tournament/presentation/pages/division_builder_wizard.dart';
import 'package:tkd_brackets/features/tournament/presentation/pages/tournament_detail_page.dart';
import 'package:tkd_brackets/features/tournament/presentation/pages/tournament_list_page.dart';
import 'package:tkd_brackets/features/auth/presentation/pages/auth_page.dart';
import 'package:tkd_brackets/features/auth/presentation/pages/organization_setup_page.dart';
import 'package:tkd_brackets/features/auth/presentation/pages/organization_dashboard_page.dart';
import 'package:tkd_brackets/features/bracket/presentation/pages/bracket_generation_page.dart';
import 'package:tkd_brackets/features/bracket/presentation/pages/bracket_page.dart';


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

/// Auth route - sign in or sign up.
@TypedGoRoute<AuthRoute>(path: '/auth')
class AuthRoute extends GoRouteData {
  const AuthRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const AuthPage();
}

/// Organization setup route - for new users without organization.
@TypedGoRoute<OrganizationSetupRoute>(path: '/organization/setup')
class OrganizationSetupRoute extends GoRouteData {
  const OrganizationSetupRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const OrganizationSetupPage();
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

/// Settings route - user settings & app configuration.
@TypedGoRoute<SettingsRoute>(path: '/settings')
class SettingsRoute extends GoRouteData {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const UserSettingsPage();
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
  Widget build(BuildContext context, GoRouterState state) =>
      TournamentDetailPage(tournamentId: tournamentId);
}

/// Tournament divisions route - for division builder wizard.
@TypedGoRoute<TournamentDivisionsRoute>(
  path: '/tournaments/:tournamentId/divisions',
)
class TournamentDivisionsRoute extends GoRouteData {
  const TournamentDivisionsRoute({required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      DivisionBuilderWizard(tournamentId: tournamentId);
}

/// Participant list route.
@TypedGoRoute<ParticipantListRoute>(
  path: '/tournaments/:tournamentId/divisions/:divisionId/participants',
)
class ParticipantListRoute extends GoRouteData {
  const ParticipantListRoute({
    required this.tournamentId,
    required this.divisionId,
  });

  final String tournamentId;
  final String divisionId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ParticipantListPage(tournamentId: tournamentId, divisionId: divisionId);
}

/// CSV Import route.
@TypedGoRoute<CsvImportRoute>(
  path: '/tournaments/:tournamentId/divisions/:divisionId/participants/import',
)
class CsvImportRoute extends GoRouteData {
  const CsvImportRoute({required this.tournamentId, required this.divisionId});

  final String tournamentId;
  final String divisionId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CSVImportPage(tournamentId: tournamentId, divisionId: divisionId);
}

/// Organization dashboard route.
@TypedGoRoute<OrganizationDashboardRoute>(path: '/organization')
class OrganizationDashboardRoute extends GoRouteData {
  const OrganizationDashboardRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const OrganizationDashboardPage();
}

/// Bracket generation route.
@TypedGoRoute<BracketGenerationRoute>(
  path: '/tournaments/:tournamentId/divisions/:divisionId/brackets',
)
class BracketGenerationRoute extends GoRouteData {
  const BracketGenerationRoute({
    required this.tournamentId,
    required this.divisionId,
  });

  final String tournamentId;
  final String divisionId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      BracketGenerationPage(
        tournamentId: tournamentId,
        divisionId: divisionId,
      );
}

/// Bracket viewer route.
@TypedGoRoute<BracketViewerRoute>(
  path: '/tournaments/:tournamentId/divisions/:divisionId/brackets/:bracketId',
)
class BracketViewerRoute extends GoRouteData {
  const BracketViewerRoute({
    required this.tournamentId,
    required this.divisionId,
    required this.bracketId,
  });

  final String tournamentId;
  final String divisionId;
  final String bracketId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      BracketPage(bracketId: bracketId);
}
