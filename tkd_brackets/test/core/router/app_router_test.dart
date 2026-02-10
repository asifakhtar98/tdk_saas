import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tkd_brackets/core/router/app_router.dart';
import 'package:tkd_brackets/core/router/routes.dart';
import 'package:tkd_brackets/core/sync/sync_service.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_state.dart';

import '../../mocks/mock_authentication_bloc.dart';
import '../../mocks/mock_sync_service.dart';

void main() {
  late MockAuthenticationBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = createMockAuthenticationBloc();
    GetIt.instance
        .registerSingleton<AuthenticationBloc>(
      mockAuthBloc,
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('AppRouter', () {
    test('should create GoRouter instance', () {
      final appRouter = AppRouter();
      expect(appRouter.router, isA<GoRouter>());
    });

    test('should have routes configured', () {
      final appRouter = AppRouter();
      final routeConfig =
          appRouter.router.configuration;
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

    test(
      'TournamentListRoute generates correct path',
      () {
        expect(
          const TournamentListRoute().location,
          '/tournaments',
        );
      },
    );

    test(
      'TournamentDetailsRoute encodes parameter '
      'in path',
      () {
        const route = TournamentDetailsRoute(
          tournamentId: 'abc-123',
        );
        expect(
          route.location,
          '/tournaments/abc-123',
        );
      },
    );

    test(
      'TournamentDetailsRoute handles special '
      'characters',
      () {
        const route = TournamentDetailsRoute(
          tournamentId: 'test%20id',
        );
        expect(
          route.location,
          '/tournaments/test%2520id',
        );
      },
    );

    test(
      'TournamentDetailsRoute handles spaces '
      'correctly',
      () {
        const route = TournamentDetailsRoute(
          tournamentId: 'test id',
        );
        expect(
          route.location,
          '/tournaments/test%20id',
        );
      },
    );
  });

  group('Route Navigation', () {
    testWidgets(
      'navigates from Home to Demo',
      (tester) async {
        final router = AppRouter();

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router.router,
          ),
        );
        await tester.pumpAndSettle();

        // Verify home page
        expect(
          find.text('TKD Brackets'),
          findsOneWidget,
        );
        expect(
          find.text('Try Demo'),
          findsOneWidget,
        );

        // Tap demo button
        await tester.tap(find.text('Try Demo'));
        await tester.pumpAndSettle();

        // Verify demo page
        expect(
          find.text('Demo Mode'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'shows error page for unknown route',
      (tester) async {
        final router = AppRouter();

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router.router,
          ),
        );
        await tester.pumpAndSettle();

        // Navigate to unknown route
        router.router.go('/unknown-route-xyz');
        await tester.pumpAndSettle();

        // Verify error page
        expect(
          find.text('Go Home'),
          findsOneWidget,
        );
      },
    );
  });

  group('Redirect Guard', () {
    setUp(() {
      final (mock, _) = createMockSyncService();
      GetIt.instance
          .registerSingleton<SyncService>(mock);
    });

    testWidgets(
      'redirects /app to /dashboard',
      (tester) async {
        final router = AppRouter();

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router.router,
          ),
        );
        await tester.pumpAndSettle();

        router.router.go('/app');
        await tester.pumpAndSettle();

        expect(
          router.router.routerDelegate
              .currentConfiguration.fullPath,
          equals('/dashboard'),
        );
      },
    );

    testWidgets(
      'redirects /app/ to /dashboard',
      (tester) async {
        final router = AppRouter();

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router.router,
          ),
        );
        await tester.pumpAndSettle();

        router.router.go('/app/');
        await tester.pumpAndSettle();

        expect(
          router.router.routerDelegate
              .currentConfiguration.fullPath,
          equals('/dashboard'),
        );
      },
    );

    testWidgets(
      'does not redirect normal shell routes',
      (tester) async {
        final router = AppRouter();

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router.router,
          ),
        );
        await tester.pumpAndSettle();

        router.router.go('/settings');
        await tester.pumpAndSettle();

        expect(
          router.router.routerDelegate
              .currentConfiguration.fullPath,
          equals('/settings'),
        );
      },
    );
  });

  group('Auth Redirect Guard', () {
    setUp(() {
      final (mock, _) = createMockSyncService();
      GetIt.instance
          .registerSingleton<SyncService>(mock);
    });

    final testUser = UserEntity(
      id: 'user-123',
      email: 'test@example.com',
      displayName: 'Test User',
      organizationId: 'org-123',
      role: UserRole.owner,
      isActive: true,
      createdAt: DateTime(2026),
    );

    testWidgets(
      'redirects authenticated user from / '
      'to /dashboard',
      (tester) async {
        mockAuthBloc.emitState(
          AuthenticationState.authenticated(testUser),
        );

        final router = AppRouter();

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router.router,
          ),
        );
        await tester.pumpAndSettle();

        // Initial location is /, should redirect
        // to /dashboard for authenticated users
        expect(
          router.router.routerDelegate
              .currentConfiguration.fullPath,
          equals('/dashboard'),
        );
      },
    );

    testWidgets(
      'redirects authenticated user from /demo '
      'to /dashboard',
      (tester) async {
        mockAuthBloc.emitState(
          AuthenticationState.authenticated(testUser),
        );

        final router = AppRouter();

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router.router,
          ),
        );
        await tester.pumpAndSettle();

        router.router.go('/demo');
        await tester.pumpAndSettle();

        expect(
          router.router.routerDelegate
              .currentConfiguration.fullPath,
          equals('/dashboard'),
        );
      },
    );

    testWidgets(
      'redirects unauthenticated user from '
      'protected route to /',
      (tester) async {
        mockAuthBloc.emitState(
          const AuthenticationState.unauthenticated(),
        );

        final router = AppRouter();

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router.router,
          ),
        );
        await tester.pumpAndSettle();

        router.router.go('/dashboard');
        await tester.pumpAndSettle();

        expect(
          router.router.routerDelegate
              .currentConfiguration.fullPath,
          equals('/'),
        );
      },
    );

    testWidgets(
      'does not redirect during '
      'checkInProgress state',
      (tester) async {
        mockAuthBloc.emitState(
          const AuthenticationState.checkInProgress(),
        );

        final router = AppRouter();

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router.router,
          ),
        );
        await tester.pumpAndSettle();

        // During check, should stay on initial route
        // (/) without being redirected
        expect(
          router.router.routerDelegate
              .currentConfiguration.fullPath,
          equals('/'),
        );
      },
    );

    testWidgets(
      'does not redirect during initial state',
      (tester) async {
        // Default state is initial, so no need
        // to call emitState

        final router = AppRouter();

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router.router,
          ),
        );
        await tester.pumpAndSettle();

        // During initial, should stay on /
        expect(
          router.router.routerDelegate
              .currentConfiguration.fullPath,
          equals('/'),
        );
      },
    );

    testWidgets(
      'allows unauthenticated user to access '
      'public routes',
      (tester) async {
        mockAuthBloc.emitState(
          const AuthenticationState.unauthenticated(),
        );

        final router = AppRouter();

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router.router,
          ),
        );
        await tester.pumpAndSettle();

        // Should stay on / (public route)
        expect(
          router.router.routerDelegate
              .currentConfiguration.fullPath,
          equals('/'),
        );

        // Navigate to /demo (also public)
        router.router.go('/demo');
        await tester.pumpAndSettle();

        expect(
          router.router.routerDelegate
              .currentConfiguration.fullPath,
          equals('/demo'),
        );
      },
    );
  });
}
