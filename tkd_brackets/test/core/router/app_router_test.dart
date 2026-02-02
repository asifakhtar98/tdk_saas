import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tkd_brackets/core/router/app_router.dart';
import 'package:tkd_brackets/core/router/routes.dart';

void main() {
  group('AppRouter', () {
    // Create fresh instance per test to avoid GlobalKey conflicts
    late AppRouter appRouter;

    setUp(() {
      appRouter = AppRouter();
    });

    test('should create GoRouter instance', () {
      expect(appRouter.router, isA<GoRouter>());
    });

    test('should have routes configured', () {
      // Verify the router has routes configured
      final routeConfig = appRouter.router.configuration;
      expect(routeConfig.routes.isNotEmpty, isTrue);
    });
  });

  group('Type-Safe Routes', () {
    test('HomeRoute generates correct path', () {
      expect(const HomeRoute().location, '/');
    });

    test('DemoRoute generates correct path', () {
      expect(const DemoRoute().location, '/demo');
    });

    test('TournamentListRoute generates correct path', () {
      expect(const TournamentListRoute().location, '/tournaments');
    });

    test('TournamentDetailsRoute encodes parameter in path', () {
      const route = TournamentDetailsRoute(tournamentId: 'abc-123');
      expect(route.location, '/tournaments/abc-123');
    });

    test('TournamentDetailsRoute handles special characters', () {
      const route = TournamentDetailsRoute(tournamentId: 'test%20id');
      // Verify the parameter is included in the path
      // URL encoding handled by go_router
      expect(route.location, '/tournaments/test%2520id');
    });

    test('TournamentDetailsRoute handles spaces correctly', () {
      const route = TournamentDetailsRoute(tournamentId: 'test id');
      // go_router encodes spaces as %20
      expect(route.location, '/tournaments/test%20id');
    });
  });

  group('Route Navigation', () {
    testWidgets('navigates from Home to Demo', (tester) async {
      final router = AppRouter();

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router.router),
      );
      await tester.pumpAndSettle();

      // Verify home page
      expect(find.text('TKD Brackets'), findsOneWidget);
      expect(find.text('Try Demo'), findsOneWidget);

      // Tap demo button
      await tester.tap(find.text('Try Demo'));
      await tester.pumpAndSettle();

      // Verify demo page
      expect(find.text('Demo Mode'), findsWidgets);
    });

    testWidgets('shows error page for unknown route', (tester) async {
      final router = AppRouter();

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router.router),
      );
      await tester.pumpAndSettle();

      // Navigate to unknown route
      router.router.go('/unknown-route-xyz');
      await tester.pumpAndSettle();

      // Verify error page
      expect(find.text('Go Home'), findsOneWidget);
    });
  });
}
