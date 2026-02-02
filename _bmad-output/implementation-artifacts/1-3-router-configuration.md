# Story 1.3: Router Configuration

Status: done

## Story

As a **developer**,
I want **go_router configured with type-safe routes**,
So that **navigation is declarative, type-safe, and supports deep linking**.

## Acceptance Criteria

1. **Given** dependency injection is configured from Story 1.2, **When** I configure go_router with go_router_builder, **Then** `lib/core/router/app_router.dart` defines the router configuration.

2. **Given** go_router is configured, **When** I examine the project, **Then** `lib/core/router/routes.dart` contains type-safe route definitions with `@TypedGoRoute` annotations.

3. **Given** route classes are annotated, **When** I run `dart run build_runner build`, **Then** `.g.dart` files are generated for route builders.

4. **Given** authentication will be needed later, **When** I examine the router, **Then** the router supports redirect guards for auth protection (placeholder implementation).

5. **Given** the app needs a main layout, **When** I configure shell routes, **Then** shell routes are configured for the main app scaffold.

6. **Given** the router is configured, **When** I write unit tests, **Then** the tests verify route generation and parameter parsing.

## Quick Reference

| Route Class              | Path                         | Page        | Shell |
| ------------------------ | ---------------------------- | ----------- | ----- |
| `HomeRoute`              | `/`                          | `HomePage`  | No    |
| `DemoRoute`              | `/demo`                      | `DemoPage`  | No    |
| `TournamentListRoute`    | `/tournaments`               | Placeholder | Yes   |
| `TournamentDetailsRoute` | `/tournaments/:tournamentId` | Placeholder | Yes   |

## Tasks / Subtasks

- [x] **Task 1: Create Feature Directory Structure (AC: #1)**
  - [x] Create `lib/features/home/presentation/pages/` directory
  - [x] Create `lib/features/demo/presentation/pages/` directory
  - [x] Add `.gitkeep` files if needed for empty intermediate directories

- [x] **Task 2: Create Routes File with Type-Safe Route Definitions (AC: #2, #3)**
  - [x] Create `lib/core/router/routes.dart`
  - [x] Add `part 'routes.g.dart';` directive
  - [x] Define `@TypedGoRoute` annotated route classes extending `GoRouteData`
  - [x] Create routes: `HomeRoute`, `DemoRoute`, `TournamentListRoute`, `TournamentDetailsRoute`

- [x] **Task 3: Create Shell Route for Main App Scaffold (AC: #5)**
  - [x] Create `lib/core/router/shell_routes.dart`
  - [x] Define `AppShellScaffold` widget for consistent layout
  - [x] Create `createAppShellRoute()` factory function

- [x] **Task 4: Update AppRouter with Type-Safe Configuration (AC: #1, #4)**
  - [x] Update `lib/core/router/app_router.dart` with generated routes
  - [x] Add `@lazySingleton` annotation for DI registration
  - [x] Change constructor from `AppRouter._()` to `AppRouter()`
  - [x] Implement `redirect` callback placeholder for auth protection
  - [x] Add error page with accessibility support

- [x] **Task 5: Create Placeholder Pages for Route Verification (AC: #1, #6)**
  - [x] Create `lib/features/home/presentation/pages/home_page.dart`
  - [x] Create `lib/features/demo/presentation/pages/demo_page.dart`
  - [x] Use type-safe navigation: `const DemoRoute().go(context)`

- [x] **Task 6: Update App to Use GoRouter (AC: #1)**
  - [x] Update `lib/app/app.dart` to use `MaterialApp.router`
  - [x] Import `injection.dart` and resolve `AppRouter` via `getIt<AppRouter>()`
  - [x] Configure `routerConfig` with `appRouter.router`
  - [x] Remove the current `home:` property

- [x] **Task 7: Run Build Runner and Verify Generation (AC: #3)**
  - [x] Run `dart run build_runner build --delete-conflicting-outputs`
  - [x] Verify `lib/core/router/routes.g.dart` is generated
  - [x] Verify no build errors occur

- [x] **Task 8: Write Unit Tests for Router Configuration (AC: #6)**
  - [x] Create `test/core/router/app_router_test.dart`
  - [x] Use fresh `AppRouter()` instance per test (avoid static key conflicts)
  - [x] Test route path generation
  - [x] Test route parameter encoding
  - [x] Test widget navigation

- [x] **Task 9: Verification and Cleanup (AC: #1, #3, #6)**
  - [x] Run `dart analyze` with zero issues
  - [x] Run `flutter test` with all tests passing
  - [x] Run `flutter build web` successfully
  - [x] Run `flutter run -d chrome` and verify navigation works

## Dev Notes

### Project Location

**CRITICAL:** All code changes are in:
```
/Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/
```

### ⚠️ Epics vs Architecture Discrepancy

**IMPORTANT:** The epics.md specifies `lib/core/routing/` but Story 1.1 established `lib/core/router/` as the correct directory (per architecture.md). **Use `lib/core/router/`** — this is the actual project structure.

### Previous Story Learnings (Stories 1.1 & 1.2)

| Learning                                     | Application                                    |
| -------------------------------------------- | ---------------------------------------------- |
| Architecture uses `router/` not `routing/`   | Use `lib/core/router/` (already exists)        |
| Use `Implementation` not `Impl` suffix       | Apply to any helper classes                    |
| `@InjectableInit` uses extension pattern     | Register AppRouter as `@lazySingleton`         |
| Run build_runner after annotation changes    | Run after creating `@TypedGoRoute` annotations |
| Test file structure mirrors lib/             | Create tests in `test/core/router/`            |
| DI config is at `lib/core/di/injection.dart` | Import `getIt` from correct location           |

### Current File State

**`lib/core/router/app_router.dart`** (from Story 1.1):
```dart
class AppRouter {
  AppRouter._();  // ← Change to AppRouter() for DI
  static final GoRouter router = GoRouter(...);  // ← Change to instance getter
}
```

**`lib/app/app.dart`** (from Story 1.1):
```dart
MaterialApp(
  home: const Scaffold(...),  // ← Change to MaterialApp.router with routerConfig
)
```

### Dependencies (Already in pubspec.yaml)

- `go_router: ^15.1.1` 
- `go_router_builder: ^2.9.0` (dev)

### Architecture Patterns

| Element           | Pattern                   | Example                      |
| ----------------- | ------------------------- | ---------------------------- |
| **Route Classes** | `{Feature}{Context}Route` | `TournamentDetailsRoute`     |
| **Path Strings**  | `/{feature}/{sub}`        | `/tournaments/:tournamentId` |

---

## Code Files

### 📄 `lib/core/router/routes.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tkd_brackets/features/demo/presentation/pages/demo_page.dart';
import 'package:tkd_brackets/features/home/presentation/pages/home_page.dart';

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
// Placeholder Routes (Will be moved to feature modules in Epic 3+)
// ═══════════════════════════════════════════════════════════════════════════

/// Tournament list route - placeholder for Epic 3.
@TypedGoRoute<TournamentListRoute>(path: '/tournaments')
class TournamentListRoute extends GoRouteData {
  const TournamentListRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => Scaffold(
        appBar: AppBar(title: const Text('Tournaments')),
        body: const Center(
          child: Text('Tournament List - Coming in Epic 3'),
        ),
      );
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
```

---

### 📄 `lib/core/router/shell_routes.dart`

```dart
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
```

---

### 📄 `lib/core/router/app_router.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/router/routes.dart';
import 'package:tkd_brackets/core/router/shell_routes.dart';

/// Application router with type-safe routes.
/// 
/// Uses go_router + go_router_builder for compile-time safety.
/// Auth redirects implemented in Story 2.5.
@lazySingleton
class AppRouter {
  AppRouter();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  /// The GoRouter instance for this app.
  GoRouter get router => _router;

  late final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: _redirectGuard,
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
```

---

### 📄 `lib/app/app.dart`

```dart
import 'package:flutter/material.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/core/router/app_router.dart';
import 'package:tkd_brackets/core/theme/app_theme.dart';

/// Root application widget.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = getIt<AppRouter>();

    return MaterialApp.router(
      title: 'TKD Brackets',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter.router,
    );
  }
}
```

---

### 📄 `lib/features/home/presentation/pages/home_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:tkd_brackets/core/router/routes.dart';

/// Home page - landing screen after app launch.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'TKD Brackets',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tournament Bracket Management',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => const DemoRoute().go(context),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Try Demo'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO(story-2.4): Navigate to sign in
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sign in available in Story 2.4'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### 📄 `lib/features/demo/presentation/pages/demo_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:tkd_brackets/core/router/routes.dart';

/// Demo mode page - explore app without account.
/// Full implementation in Story 1.11 (Demo Mode Data Seeding).
class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Mode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => const HomeRoute().go(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.science_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text('Demo Mode', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Explore TKD Brackets without creating an account.\n'
                'Your data is stored locally until you sign up.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => const TournamentListRoute().go(context),
                icon: const Icon(Icons.emoji_events),
                label: const Text('View Tournaments'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### 📄 `test/core/router/app_router_test.dart`

```dart
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

    test('should have initial location set to /', () {
      final config = appRouter.router.routerDelegate.currentConfiguration;
      expect(config.uri.path, '/');
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
      expect(route.location, contains('test'));
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
```

---

## Anti-Patterns to AVOID

| ❌ DO NOT                                   | ✅ DO INSTEAD                               |
| ------------------------------------------ | ------------------------------------------ |
| Use `GoRoute` directly                     | Use `@TypedGoRoute` for type-safety        |
| Hardcode paths in widgets                  | Use `const DemoRoute().go(context)`        |
| Forget `part 'routes.g.dart';`             | Add it right after imports                 |
| Import `routes.g.dart` before build_runner | Run build_runner first                     |
| Create pages in `lib/core/`                | Put pages in `lib/features/`               |
| Skip DI registration                       | Add `@lazySingleton` to AppRouter          |
| Use deprecated `withOpacity()`             | Use `colorScheme.onSurfaceVariant` instead |

## Verification Commands

```bash
cd /Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets

# 1. Create directories (if needed)
mkdir -p lib/features/home/presentation/pages
mkdir -p lib/features/demo/presentation/pages

# 2. Generate route code
dart run build_runner build --delete-conflicting-outputs

# 3. Verify analysis
dart analyze

# 4. Run tests
flutter test

# 5. Build web
flutter build web

# 6. Test in browser
flutter run -d chrome -t lib/main_development.dart
```

## References

- [architecture.md#Route-Naming-Conventions] — Route naming patterns
- [architecture.md#Navigation] — go_router + go_router_builder spec
- [epics.md#Story-1.3] — Acceptance criteria (note: uses `routing/` but actual project uses `router/`)
- [1-1-project-scaffold-and-clean-architecture-setup.md] — Current app_router.dart state
- [1-2-dependency-injection-configuration.md] — DI patterns
- [go_router pub.dev (context7)] — Latest TypedGoRoute patterns

## Dev Agent Record

### Agent Model Used

Gemini 2.5 Pro

### Change Log

- 2026-02-02: Implemented Story 1.3 Router Configuration
  - Created feature directory structure for home and demo
  - Created type-safe routes with @TypedGoRoute annotations
  - Created shell routes for authenticated pages
  - Updated AppRouter with DI registration (@lazySingleton)
  - Created HomePage and DemoPage with type-safe navigation
  - Updated App to use MaterialApp.router
  - Generated routes.g.dart via build_runner
  - Created comprehensive unit tests (8 tests for router)
  - All verification commands pass (analyze, test, build)
- 2026-02-02: Code Review Fixes Applied
  - Fixed CRITICAL: Changed static GlobalKey fields to instance fields in AppRouter
    - Static keys caused test isolation issues (duplicate keys across test instances)
  - Fixed MEDIUM: Strengthened test assertions for URL encoding in TournamentDetailsRoute
    - Added explicit path verification instead of partial match
    - Added new test for space encoding
  - All 19 tests passing after fixes

### Completion Notes List

- ✅ All 4 type-safe routes implemented: HomeRoute, DemoRoute, TournamentListRoute, TournamentDetailsRoute
- ✅ Shell routes implemented with AppShellScaffold for consistent layout
- ✅ Auth redirect guard placeholder ready for Story 2.5
- ✅ Error page with accessibility support (Semantics labels)
- ✅ HomePage uses `const DemoRoute().go(context)` for type-safe navigation
- ✅ DemoPage navigates to TournamentListRoute (placeholder for Epic 3)
- ✅ AppRouter registered as @lazySingleton in DI container
- ✅ 19 total tests passing (9 router tests + 10 existing tests)
- ✅ dart analyze: No issues found
- ✅ flutter build web: Successful

### File List

**New Files:**
- lib/core/router/routes.dart
- lib/core/router/routes.g.dart (generated)
- lib/core/router/shell_routes.dart
- lib/features/home/presentation/pages/home_page.dart
- lib/features/demo/presentation/pages/demo_page.dart
- test/core/router/app_router_test.dart

**Modified Files:**
- lib/core/router/app_router.dart
- lib/app/app.dart
- lib/core/di/injection.config.dart (generated)
