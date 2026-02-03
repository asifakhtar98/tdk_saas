# Story 1.7: Sentry Error Tracking Integration

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer**,
I want **Sentry integrated for crash reporting and error tracking**,
So that **production errors are automatically captured and reported**.

## Acceptance Criteria

1. **Given** Supabase and error handling are configured, **When** I examine the monitoring directory, **Then** `lib/core/monitoring/sentry_service.dart` initializes Sentry SDK.

2. **Given** the SentryService exists, **When** I examine the ErrorReportingService, **Then** `Sentry.captureException` is called for exception reporting (replacing TODO markers).

3. **Given** the router is configured, **When** I examine the AppRouter, **Then** `SentryNavigatorObserver` is added as a navigator observer for navigation breadcrumbs.

4. **Given** the app uses environment configuration, **When** I examine the initialization, **Then** environment-specific DSN is loaded from build-time `--dart-define` variables.

5. **Given** Sentry configuration exists, **When** the app runs in development mode, **Then** Sentry is disabled (no events sent to Sentry) to avoid polluting error tracking.

6. **Given** the Sentry implementation exists, **When** I run unit tests, **Then** they verify error capture calls using mocks.

## Current Implementation State

### ✅ Already Implemented (from Stories 1.1-1.6)

| Component             | Location                                      | Status                            |
| --------------------- | --------------------------------------------- | --------------------------------- |
| Project scaffold      | `lib/`                                        | ✅ Complete                        |
| DI configuration      | `lib/core/di/injection.dart`                  | ✅ Complete                        |
| Router configuration  | `lib/core/router/app_router.dart`             | ✅ Complete (needs observer added) |
| Error handling        | `lib/core/error/`                             | ✅ Complete                        |
| ErrorReportingService | `lib/core/error/error_reporting_service.dart` | ✅ Complete (has TODO markers)     |
| Supabase config       | `lib/core/config/supabase_config.dart`        | ✅ Complete                        |
| Bootstrap function    | `lib/bootstrap.dart`                          | ✅ Complete (has TODO marker)      |
| sentry_flutter        | pubspec.yaml                                  | ✅ Already added (v8.12.0)         |

### ❌ Missing (To Be Implemented This Story)

1. **`lib/core/monitoring/sentry_service.dart`** — Sentry initialization static service (new file)
2. **Update `lib/bootstrap.dart`** — Wrap app with SentryFlutter.init
3. **Update `lib/core/error/error_reporting_service.dart`** — Replace TODO markers with Sentry calls
4. **Update `lib/core/router/app_router.dart`** — Add SentryNavigatorObserver
5. **Unit tests** in `test/core/monitoring/`

## Tasks / Subtasks

- [ ] **Task 1: Create SentryService (AC: #1, #4, #5)**
  - [ ] Create `lib/core/monitoring/` directory
  - [ ] Create `lib/core/monitoring/sentry_service.dart`
  - [ ] Implement `SentryService.initialize()` static method
  - [ ] Load DSN from `SENTRY_DSN` dart-define
  - [ ] Set environment from `ENVIRONMENT` dart-define
  - [ ] Configure `tracesSampleRate = 0.2` for performance monitoring
  - [ ] Disable Sentry when DSN is empty (development mode)

- [ ] **Task 2: Update Bootstrap for Sentry Init (AC: #4, #5)**
  - [ ] Update `lib/bootstrap.dart` to call `SentryService.initialize()`
  - [ ] Use `SentryFlutter.init` with `appRunner` callback pattern
  - [ ] Initialize Sentry AFTER Supabase, BEFORE DI
  - [ ] Pass `sentryDsn` parameter (can be empty for dev)

- [ ] **Task 3: Update ErrorReportingService (AC: #2)**
  - [ ] Remove all TODO(story-1.7) markers
  - [ ] Implement `Sentry.captureException()` in `reportException()`
  - [ ] Implement `Sentry.captureMessage()` in `reportFailure()` and `reportError()`
  - [ ] Implement `Sentry.addBreadcrumb()` in `addBreadcrumb()`
  - [ ] Implement `Sentry.configureScope()` in `setUserContext()` and `clearUserContext()`
  - [ ] Guard all Sentry calls to check if initialized (no-op when disabled)

- [ ] **Task 4: Add SentryNavigatorObserver (AC: #3)**
  - [ ] Update `lib/core/router/app_router.dart`
  - [ ] Add `SentryNavigatorObserver()` to GoRouter observers list
  - [ ] Ensure observer only added when Sentry is enabled
  - [ ] **TIMING NOTE:** DI runs AFTER Sentry.init(), so `isEnabled` is set correctly when AppRouter instantiates

- [ ] **Task 5: Update Main Entry Points (AC: #4)**
  - [ ] Update `lib/main_development.dart` — pass empty DSN (disabled)
  - [ ] Update `lib/main_staging.dart` — pass DSN from dart-define
  - [ ] Update `lib/main_production.dart` — pass DSN from dart-define

- [ ] **Task 6: Write Unit Tests (AC: #6)**
  - [ ] Create `test/core/monitoring/sentry_service_test.dart`
  - [ ] Test initialization with valid DSN
  - [ ] Test initialization with empty DSN (disabled mode)
  - [ ] Test `isEnabled` property
  - [ ] Update `test/core/error/error_reporting_service_test.dart`
  - [ ] Add `SentryService.resetForTesting()` to `setUp()` (**CRITICAL**)
  - [ ] Existing tests will pass because SentryService calls are no-op when disabled

- [ ] **Task 7: Verification**
  - [ ] Run `dart analyze` with zero issues
  - [ ] Run `flutter test` with all tests passing
  - [ ] Run `flutter build web` successfully
  - [ ] Verify Sentry disabled in dev (no console errors about DSN)

## Dev Notes

### Project Location

**CRITICAL:** All code changes are in:
```
/Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/
```

### File Location (Per Architecture)

**IMPORTANT:** Create new `monitoring/` directory under `lib/core/`:
```
lib/core/monitoring/
└── sentry_service.dart    # NEW - Sentry initialization
```

This follows the architecture pattern where monitoring services live under `core/`.

### Dependencies (Already in pubspec.yaml)

```yaml
dependencies:
  sentry_flutter: ^8.12.0
```

No new dependencies required — `sentry_flutter` was added in Story 1.1.

### Previous Story Learnings (Stories 1.1-1.6)

| Learning                                       | Application                             |
| ---------------------------------------------- | --------------------------------------- |
| Static config classes pattern (SupabaseConfig) | Apply same pattern to SentryService     |
| Tests mirror `lib/` directory structure        | Create tests in `test/core/monitoring/` |
| Guard access before initialization             | Check `isEnabled` before Sentry calls   |
| ErrorReportingService has TODO markers         | Replace with real Sentry calls          |
| Bootstrap order matters                        | Sentry init AFTER Supabase, BEFORE DI   |
| Empty string for disabled services             | Empty DSN = Sentry disabled             |

---

## Architecture Requirements

### From Architecture Document

**Infrastructure Decisions (lines 486-520):**

| Decision           | Choice                    | Rationale                                 |
| ------------------ | ------------------------- | ----------------------------------------- |
| **Error Tracking** | Sentry (`sentry_flutter`) | Free tier (5K errors/mo), no Firebase dep |

**Sentry Setup Pattern (from architecture):**
```dart
await SentryFlutter.init(
  (options) {
    options.dsn = const String.fromEnvironment('SENTRY_DSN');
    options.tracesSampleRate = 0.2; // 20% of transactions for performance
    options.environment = const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  },
  appRunner: () => runApp(const App()),
);
```

**Error Handling Integration (from ErrorReportingService TODO markers):**
```dart
// For exceptions:
await Sentry.captureException(exception, stackTrace: stackTrace);

// For messages:
await Sentry.captureMessage(message, level: SentryLevel.warning);

// For breadcrumbs:
Sentry.addBreadcrumb(Breadcrumb(message: message, category: category));

// For user context:
Sentry.configureScope((scope) => scope.setUser(SentryUser(id: userId)));
```

### Naming Conventions

| Element       | Pattern         | Example                    |
| ------------- | --------------- | -------------------------- |
| Service Class | `SentryService` | Static initialization      |
| Directory     | `monitoring/`   | Under `lib/core/`          |
| Test File     | `*_test.dart`   | `sentry_service_test.dart` |

---

## Code Specifications

### 📄 `lib/core/monitoring/sentry_service.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Provides Sentry error tracking initialization and access.
///
/// Must be called in bootstrap.dart BEFORE DI container initialization.
/// Sentry is disabled when DSN is empty (development mode).
///
/// Usage:
/// ```dart
/// await SentryService.initialize(
///   dsn: 'https://...@sentry.io/...',
///   environment: 'production',
/// );
/// ```
class SentryService {
  SentryService._();

  static bool _initialized = false;
  static bool _enabled = false;

  /// Whether Sentry has been initialized.
  static bool get isInitialized => _initialized;

  /// Whether Sentry is enabled (DSN was provided).
  /// Use this to guard Sentry calls throughout the app.
  static bool get isEnabled => _enabled;

  /// Initializes Sentry error tracking.
  ///
  /// If [dsn] is empty, Sentry is disabled (no events sent).
  /// This allows development builds to run without Sentry configuration.
  ///
  /// [environment] should be 'development', 'staging', or 'production'.
  /// [tracesSampleRate] controls performance monitoring (0.0 to 1.0).
  /// [appRunner] is the callback to run the app after Sentry init.
  ///
  /// Throws [StateError] if called more than once.
  static Future<void> initialize({
    required String dsn,
    required String environment,
    double tracesSampleRate = 0.2,
    required Future<void> Function() appRunner,
  }) async {
    if (_initialized) {
      throw StateError('SentryService.initialize() called more than once.');
    }

    _initialized = true;

    // If DSN is empty, skip Sentry init (development mode)
    if (dsn.isEmpty) {
      _enabled = false;
      if (kDebugMode) {
        // ignore: avoid_print
        print('[SentryService] Disabled - no DSN provided (development mode)');
      }
      await appRunner();
      return;
    }

    _enabled = true;

    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment = environment;
        options.tracesSampleRate = tracesSampleRate;
        // Disable in debug builds even if DSN provided
        options.debug = kDebugMode;
        // Attach screenshots on crash (default is true)
        options.attachScreenshot = true;
        // Track app lifecycle events as breadcrumbs
        options.enableAutoSessionTracking = true;
      },
      appRunner: appRunner,
    );
  }

  /// Captures an exception to Sentry.
  /// No-op if Sentry is disabled.
  static Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? context,
  }) async {
    if (!_enabled) return;

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      hint: context != null ? Hint.withMap({'context': context}) : null,
    );
  }

  /// Captures a message to Sentry.
  /// No-op if Sentry is disabled.
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? params,
  }) async {
    if (!_enabled) return;

    await Sentry.captureMessage(
      message,
      level: level,
      params: params?.values.toList(),
    );
  }

  /// Adds a breadcrumb for debugging context.
  /// No-op if Sentry is disabled.
  static void addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
  }) {
    if (!_enabled) return;

    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        data: data,
      ),
    );
  }

  /// Sets user context for all future events.
  /// No-op if Sentry is disabled.
  static void setUserContext({
    required String userId,
    String? email,
    String? organizationId,
  }) {
    if (!_enabled) return;

    Sentry.configureScope((scope) {
      scope.setUser(
        SentryUser(
          id: userId,
          email: email,
          data: organizationId != null
              ? {'organization_id': organizationId}
              : null,
        ),
      );
    });
  }

  /// Clears user context (e.g., on logout).
  /// No-op if Sentry is disabled.
  static void clearUserContext() {
    if (!_enabled) return;

    Sentry.configureScope((scope) => scope.setUser(null));
  }

  /// Resets initialization state for testing.
  /// WARNING: Only use in tests.
  @visibleForTesting
  static void resetForTesting() {
    _initialized = false;
    _enabled = false;
  }
}
```

### 📄 `lib/bootstrap.dart` (Updated)

```dart
import 'package:flutter/material.dart';
import 'package:tkd_brackets/app/app.dart';
import 'package:tkd_brackets/core/config/supabase_config.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/core/monitoring/sentry_service.dart';

/// Shared initialization for all flavors.
/// This function configures services before launching the app.
Future<void> bootstrap({
  required String environment,
  required String supabaseUrl,
  required String supabaseAnonKey,
  required String sentryDsn,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase FIRST (before DI so client is available for injection)
  // Debug mode enabled only in development for network request logging.
  await SupabaseConfig.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: environment == 'development',
  );

  // Initialize Sentry with appRunner pattern
  // Empty DSN disables Sentry (development mode)
  await SentryService.initialize(
    dsn: sentryDsn,
    environment: environment,
    tracesSampleRate: 0.2,
    appRunner: () async {
      // Initialize DI container (can now inject SupabaseClient)
      configureDependencies(environment);

      runApp(const App());
    },
  );
}
```

### 📄 `lib/main_development.dart` (Updated)

```dart
import 'package:tkd_brackets/bootstrap.dart';

void main() {
  bootstrap(
    environment: 'development',
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    // Empty string = Sentry disabled in development
    sentryDsn: '',
  );
}
```

### 📄 `lib/main_staging.dart` (Updated)

```dart
import 'package:tkd_brackets/bootstrap.dart';

void main() {
  bootstrap(
    environment: 'staging',
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    sentryDsn: const String.fromEnvironment('SENTRY_DSN'),
  );
}
```

### 📄 `lib/main_production.dart` (Updated)

```dart
import 'package:tkd_brackets/bootstrap.dart';

void main() {
  bootstrap(
    environment: 'production',
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    sentryDsn: const String.fromEnvironment('SENTRY_DSN'),
  );
}
```

### 📄 `lib/core/error/error_reporting_service.dart` (Updated)

```dart
import 'package:injectable/injectable.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/monitoring/sentry_service.dart';
import 'package:tkd_brackets/core/services/logger_service.dart';

/// Centralized error reporting service for handling and logging errors.
///
/// This service provides a unified interface for reporting errors throughout
/// the application. It integrates with both local logging and Sentry.
///
/// All use cases and repositories should use this service to report errors
/// rather than logging directly.
@lazySingleton
class ErrorReportingService {
  ErrorReportingService(this._loggerService);

  final LoggerService _loggerService;

  /// Reports a domain-layer Failure.
  ///
  /// Use this method when a use case or repository encounters a Failure.
  /// The userFriendlyMessage is logged at warning level, and technicalDetails
  /// (if available) are logged at error level.
  void reportFailure(Failure failure) {
    _loggerService.warning(
      'Failure: ${failure.runtimeType} - ${failure.userFriendlyMessage}',
    );

    if (failure.technicalDetails != null) {
      _loggerService.error(
        'Technical details: ${failure.technicalDetails}',
      );
    }

    // Send to Sentry (no-op if disabled)
    SentryService.captureMessage(
      failure.userFriendlyMessage,
      level: SentryLevel.warning,
      params: {'type': failure.runtimeType.toString()},
    );
  }

  /// Reports a data-layer Exception with stack trace.
  ///
  /// Use this method when catching exceptions in data sources or repositories.
  /// The exception message and stack trace are logged.
  void reportException(
    Object exception,
    StackTrace stackTrace, {
    String? context,
  }) {
    final contextPrefix = context != null ? '[$context] ' : '';
    _loggerService.error(
      '${contextPrefix}Exception: ${exception.runtimeType}',
      exception,
      stackTrace,
    );

    // Send to Sentry (no-op if disabled)
    SentryService.captureException(
      exception,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Reports a generic error message.
  ///
  /// Use this method for general error reporting when you don't have a
  /// structured Failure or Exception.
  void reportError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _loggerService.error(message, error, stackTrace);

    // Send to Sentry (no-op if disabled)
    SentryService.captureMessage(message, level: SentryLevel.error);
  }

  /// Adds a breadcrumb for tracking user actions.
  ///
  /// Breadcrumbs provide context for debugging by tracking the sequence
  /// of events leading up to an error.
  void addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
  }) {
    // Log breadcrumb locally
    final categoryPrefix = category != null ? '[$category] ' : '';
    _loggerService.info('Breadcrumb: $categoryPrefix$message');

    // Add to Sentry (no-op if disabled)
    SentryService.addBreadcrumb(
      message: message,
      category: category,
      data: data,
    );
  }

  /// Sets user context for error tracking.
  ///
  /// Call this after successful authentication to associate errors with users.
  void setUserContext({
    required String userId,
    String? email,
    String? organizationId,
  }) {
    _loggerService.info(
      'User context set: userId=$userId, orgId=$organizationId',
    );

    // Set Sentry user (no-op if disabled)
    SentryService.setUserContext(
      userId: userId,
      email: email,
      organizationId: organizationId,
    );
  }

  /// Clears user context (e.g., on logout).
  void clearUserContext() {
    _loggerService.info('User context cleared');

    // Clear Sentry user (no-op if disabled)
    SentryService.clearUserContext();
  }
}
```

### 📄 `lib/core/router/app_router.dart` (Updated)

```dart
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
```

### 📄 `test/core/monitoring/sentry_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/monitoring/sentry_service.dart';

void main() {
  setUp(() {
    SentryService.resetForTesting();
  });

  group('SentryService initialization', () {
    test('should report not initialized before initialize() called', () {
      expect(SentryService.isInitialized, false);
      expect(SentryService.isEnabled, false);
    });

    test('should throw StateError when initialized twice', () async {
      var appRunnerCalled = false;

      // First init with empty DSN (disabled mode - doesn't require real Sentry)
      await SentryService.initialize(
        dsn: '',
        environment: 'test',
        appRunner: () async {
          appRunnerCalled = true;
        },
      );

      expect(appRunnerCalled, true);
      expect(SentryService.isInitialized, true);

      // Second init should throw
      expect(
        () => SentryService.initialize(
          dsn: '',
          environment: 'test',
          appRunner: () async {},
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('called more than once'),
          ),
        ),
      );
    });

    test('should be disabled when DSN is empty', () async {
      await SentryService.initialize(
        dsn: '',
        environment: 'development',
        appRunner: () async {},
      );

      expect(SentryService.isInitialized, true);
      expect(SentryService.isEnabled, false);
    });

    test('should call appRunner when DSN is empty', () async {
      var appRunnerCalled = false;

      await SentryService.initialize(
        dsn: '',
        environment: 'development',
        appRunner: () async {
          appRunnerCalled = true;
        },
      );

      expect(appRunnerCalled, true);
    });
  });

  group('SentryService methods with disabled state', () {
    setUp(() async {
      // Initialize in disabled mode
      await SentryService.initialize(
        dsn: '',
        environment: 'test',
        appRunner: () async {},
      );
    });

    test('captureException should be no-op when disabled', () async {
      // Should not throw
      await SentryService.captureException(
        Exception('test'),
        stackTrace: StackTrace.current,
      );
    });

    test('captureMessage should be no-op when disabled', () async {
      // Should not throw
      await SentryService.captureMessage('test message');
    });

    test('addBreadcrumb should be no-op when disabled', () {
      // Should not throw
      SentryService.addBreadcrumb(
        message: 'test breadcrumb',
        category: 'test',
      );
    });

    test('setUserContext should be no-op when disabled', () {
      // Should not throw
      SentryService.setUserContext(
        userId: 'user-123',
        email: 'test@example.com',
      );
    });

    test('clearUserContext should be no-op when disabled', () {
      // Should not throw
      SentryService.clearUserContext();
    });
  });

  group('SentryService resetForTesting', () {
    test('should reset all state', () async {
      await SentryService.initialize(
        dsn: '',
        environment: 'test',
        appRunner: () async {},
      );

      expect(SentryService.isInitialized, true);

      SentryService.resetForTesting();

      expect(SentryService.isInitialized, false);
      expect(SentryService.isEnabled, false);
    });
  });

  // Note: Tests with real Sentry DSN require integration test setup.
  // The unit tests above validate the guard logic and disabled-mode behavior.
  // 
  // For integration testing with actual Sentry:
  // 1. Create a test Sentry project
  // 2. Use environment variables for DSN
  // 3. Run as integration tests (flutter test integration_test/)
}
```

---

## Testing Strategy

### Unit Tests

| Test                                    | Purpose                               |
| --------------------------------------- | ------------------------------------- |
| `isInitialized` returns false initially | Guard logic works before init         |
| `isEnabled` returns false initially     | Disabled by default                   |
| Initialize twice throws StateError      | Prevents double initialization        |
| Empty DSN results in disabled state     | Development mode works correctly      |
| `appRunner` called when DSN empty       | App still starts in dev mode          |
| All Sentry methods no-op when disabled  | No crashes when Sentry not configured |
| `resetForTesting` resets all state      | Test isolation works                  |

### Integration Verification (Manual)

After implementation, verify:

1. **Development mode (Sentry disabled):**
   ```bash
   flutter run -d chrome \
     --dart-define=SUPABASE_URL=https://... \
     --dart-define=SUPABASE_ANON_KEY=...
   # Should see: "[SentryService] Disabled - no DSN provided"
   # App should work normally with no Sentry errors
   ```

2. **Production mode (Sentry enabled):**
   ```bash
   flutter run -d chrome \
     --dart-define=SUPABASE_URL=https://... \
     --dart-define=SUPABASE_ANON_KEY=... \
     --dart-define=SENTRY_DSN=https://...@sentry.io/... \
     --dart-define=ENVIRONMENT=production
   # Should initialize Sentry and capture events
   ```

### ErrorReportingService Test Updates (**CRITICAL**)

The existing `error_reporting_service_test.dart` tests will continue to work after adding Sentry calls because:

1. `SentryService` uses static methods with `isEnabled` guards
2. When `isEnabled` is false, all Sentry calls are no-op
3. Tests never call `SentryService.initialize()`, so `isEnabled` defaults to false

**Required change in test file:**

```dart
import 'package:tkd_brackets/core/monitoring/sentry_service.dart';

void main() {
  late ErrorReportingService errorReportingService;
  late MockLoggerService mockLoggerService;

  setUp(() {
    // CRITICAL: Reset SentryService to ensure clean state between tests
    SentryService.resetForTesting();
    
    mockLoggerService = MockLoggerService();
    errorReportingService = ErrorReportingService(mockLoggerService);
  });

  // ... existing tests continue to work unchanged ...
}
```

**Why this works:** `SentryService.isEnabled` defaults to `false`, so all `SentryService.captureException()`, `SentryService.captureMessage()`, etc. calls return immediately without doing anything. The tests only verify `LoggerService` behavior, which is still correct.

---

## File Structure After Implementation

```
lib/core/monitoring/
└── sentry_service.dart          # NEW - Sentry initialization

lib/core/error/
├── error_reporting_service.dart # UPDATED - Sentry integration
├── exceptions.dart
└── failures.dart

lib/core/router/
├── app_router.dart              # UPDATED - SentryNavigatorObserver
├── routes.dart
├── routes.g.dart
└── shell_routes.dart

lib/
├── bootstrap.dart               # UPDATED - Sentry init
├── main_development.dart        # UPDATED - empty DSN
├── main_staging.dart            # UPDATED - DSN from env
└── main_production.dart         # UPDATED - DSN from env

test/core/monitoring/
└── sentry_service_test.dart     # NEW - Unit tests
```

---

## Critical Guardrails

### ⚠️ DO NOT

- ❌ Store Sentry DSN in source code (use `--dart-define`)
- ❌ Enable Sentry in development builds (pollutes error data)
- ❌ Call Sentry methods without checking `isEnabled`
- ❌ Initialize Sentry before Supabase (order matters)
- ❌ Use `Sentry.captureException` directly (use SentryService wrapper)
- ❌ Skip the `appRunner` pattern (required for proper initialization)

### ✅ MUST

- ✅ Use empty DSN string to disable Sentry (not `null`)
- ✅ Follow `SentryFlutter.init` with `appRunner` callback pattern
- ✅ Check `SentryService.isEnabled` before adding observer
- ✅ Wrap all Sentry calls with `isEnabled` guard
- ✅ Initialize order: Supabase → Sentry → DI → runApp
- ✅ Add `SentryNavigatorObserver` for navigation breadcrumbs
- ✅ Set `tracesSampleRate = 0.2` for 20% performance sampling

---

## Verification Commands

```bash
# From tkd_brackets/ directory:

# 1. Analyze for errors
dart analyze

# 2. Run tests
flutter test

# 3. Build web (validates compilation)
flutter build web

# 4. Run locally (development - Sentry disabled)
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key

# 5. Run locally (production - Sentry enabled)
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=SENTRY_DSN=https://...@sentry.io/... \
  --dart-define=ENVIRONMENT=production
```

---

## Future Story Notes

**Story 2.x (Authentication)** will use `setUserContext()` after successful login:
```dart
ErrorReportingService.setUserContext(
  userId: user.id,
  email: user.email,
  organizationId: user.organizationId,
);
```

**Story 1.8 (Connectivity Monitoring)** may add network status breadcrumbs.

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List

| File                                          | Action   |
| --------------------------------------------- | -------- |
| lib/core/monitoring/sentry_service.dart       | Created  |
| lib/bootstrap.dart                            | Modified |
| lib/main_development.dart                     | Modified |
| lib/main_staging.dart                         | Modified |
| lib/main_production.dart                      | Modified |
| lib/core/error/error_reporting_service.dart   | Modified |
| lib/core/router/app_router.dart               | Modified |
| test/core/monitoring/sentry_service_test.dart | Created  |
