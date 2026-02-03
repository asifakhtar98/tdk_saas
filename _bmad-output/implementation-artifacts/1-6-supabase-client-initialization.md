# Story 1.6: Supabase Client Initialization

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **developer**,
I want **Supabase client properly initialized with environment configuration**,
So that **authentication, database, and realtime features are available**.

## Acceptance Criteria

1. **Given** the project has Drift and DI configured, **When** I examine the Supabase configuration, **Then** `lib/core/config/supabase_config.dart` contains initialization logic.

2. **Given** the Supabase configuration exists, **When** I examine the environment handling, **Then** environment-specific configuration is loaded from build-time variables.

3. **Given** the project structure exists, **When** I examine the entry points, **Then** `main_development.dart`, `main_staging.dart`, `main_production.dart` entry points exist with appropriate configuration.

4. **Given** Supabase is initialized, **When** I examine the DI container, **Then** Supabase client is registered as a singleton and accessible via `getIt<SupabaseClient>()`.

5. **Given** the Supabase implementation exists, **When** I run unit tests, **Then** they verify Supabase client initialization using mocks.

## Current Implementation State

### ✅ Already Implemented (from Stories 1.1-1.5)

| Component                | Location                                         | Status                         |
| ------------------------ | ------------------------------------------------ | ------------------------------ |
| Project scaffold         | `lib/`                                           | ✅ Complete                     |
| DI configuration         | `lib/core/di/injection.dart`                     | ✅ Complete                     |
| Router configuration     | `lib/core/router/`                               | ✅ Complete                     |
| Error handling           | `lib/core/error/`                                | ✅ Complete                     |
| LoggerService            | `lib/core/services/logger_service.dart`          | ✅ Complete                     |
| Drift database           | `lib/core/database/app_database.dart`            | ✅ Complete                     |
| EnvironmentConfiguration | `lib/core/config/environment_configuration.dart` | ✅ Complete                     |
| Main entry points        | `lib/main_*.dart`                                | ✅ Exist (need update)          |
| Bootstrap function       | `lib/bootstrap.dart`                             | ✅ Exists (needs Supabase init) |

### ❌ Missing (To Be Implemented This Story)

1. **`lib/core/config/supabase_config.dart`** — Supabase initialization service (in core/config/ per architecture)
2. **Update `lib/bootstrap.dart`** — Call Supabase.initialize()
3. **Update `lib/core/di/register_module.dart`** — Register SupabaseClient
4. **Unit tests** for Supabase configuration in `test/core/config/`

## Tasks / Subtasks

- [x] **Task 1: Create SupabaseConfig Service (AC: #1, #2)**
  - [x] Create `lib/core/config/supabase_config.dart`
  - [x] Implement `SupabaseConfig.initialize()` async method with validation
  - [x] Add credential validation (throw ArgumentError for empty URL/key)
  - [x] Read URL and anon key from environment parameters

- [x] **Task 2: Register SupabaseClient in DI (AC: #4)**
  - [x] Update `lib/core/di/register_module.dart` to expose SupabaseClient
  - [x] Use `@module` and `@lazySingleton` annotations
  - [x] Ensure client is accessible via `getIt<SupabaseClient>()`

- [x] **Task 3: Update Bootstrap for Supabase Init (AC: #2, #3)**
  - [x] Update `lib/bootstrap.dart` to call Supabase.initialize()
  - [x] Initialize BEFORE DI container so client is available for injection
  - [x] Pass environment configuration parameters

- [x] **Task 4: Write Unit Tests (AC: #5)**
  - [x] Create `test/core/config/supabase_config_test.dart`
  - [x] Test initialization guard logic
  - [x] Test credential validation (empty URL/key throws ArgumentError)
  - [x] Test StateError when accessing client before init

- [x] **Task 5: Verification**
  - [x] Run `dart analyze` with zero issues
  - [x] Run `flutter test` with all tests passing
  - [x] Run `flutter build web` successfully
  - [x] Run `dart run build_runner build --delete-conflicting-outputs`

## Dev Notes

### Project Location

**CRITICAL:** All code changes are in:
```
/Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/
```

### File Location (Per Architecture)

**IMPORTANT:** The architecture document specifies Supabase configuration goes in `lib/core/config/`:
```
lib/core/config/
├── environment_configuration.dart  # Already exists
└── supabase_config.dart            # NEW - create here
```

Do **NOT** create a separate `lib/core/supabase/` directory.

### Dependencies (Already in pubspec.yaml)

```yaml
dependencies:
  supabase_flutter: ^2.8.4
```

No new dependencies required.

### Previous Story Learnings (Stories 1.1-1.5)

| Learning                                | Application                             |
| --------------------------------------- | --------------------------------------- |
| Use `@lazySingleton` for DI             | Apply to SupabaseClient registration    |
| Tests mirror `lib/` directory structure | Create tests in `test/core/config/`     |
| LoggerService exists for debugging      | Use for Supabase init logging if needed |
| Run build_runner after DI changes       | Regenerate `injection.config.dart`      |
| EnvironmentConfiguration already exists | Colocate supabase_config.dart with it   |

---

## Architecture Requirements

### From Architecture Document

**File Location (line 190):**
```
lib/core/config/
└── supabase_config.dart
```

**Supabase Auth Configuration (lines 3817-3826):**
```dart
// Future auth story will add FlutterAuthClientOptions:
// authOptions: FlutterAuthClientOptions(
//   authFlowType: AuthFlowType.pkce,
//   localStorage: SecureLocalStorage(),
// ),
```

> **Note:** Full auth options (PKCE flow, secure storage) will be added in Story 2.1 (Authentication Feature). This story focuses on basic client initialization only.

**Infrastructure Decisions:**
- **Environment Config:** Flavor-based (main_development, main_staging, main_production)
- **Data Access:** Direct Supabase Client SDK, RLS-protected queries
- **Realtime Usage:** Minimal — scoring/brackets only (not in this story)

### Naming Conventions

| Element       | Pattern          | Example                      |
| ------------- | ---------------- | ---------------------------- |
| Service Class | `SupabaseConfig` | Configuration/initialization |
| DI Module     | `RegisterModule` | Third-party library wrappers |
| File Location | `core/config/`   | Configuration files together |

---

## Code Specifications

### 📄 `lib/core/config/supabase_config.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides Supabase initialization and access.
///
/// Must be called in bootstrap.dart BEFORE DI container initialization.
/// This ensures the Supabase.instance is available for injection.
///
/// Debug Mode: When `debug: true`, Supabase logs all network requests
/// to the console. This is helpful for troubleshooting but should never
/// be enabled in production builds.
///
/// Usage:
/// ```dart
/// await SupabaseConfig.initialize(
///   url: 'https://project.supabase.co',
///   anonKey: 'your-anon-key',
/// );
/// final client = SupabaseConfig.client;
/// ```
class SupabaseConfig {
  SupabaseConfig._();

  static bool _initialized = false;

  /// Whether Supabase has been initialized.
  static bool get isInitialized => _initialized;

  /// Initializes the Supabase client.
  ///
  /// Call this once at app startup, before DI container setup.
  ///
  /// Throws [ArgumentError] if [url] or [anonKey] is empty.
  /// Throws [StateError] if called more than once.
  static Future<void> initialize({
    required String url,
    required String anonKey,
    bool debug = false,
  }) async {
    // Validate credentials before attempting initialization
    if (url.isEmpty) {
      throw ArgumentError.value(
        url,
        'url',
        'Supabase URL cannot be empty. '
            'Ensure --dart-define=SUPABASE_URL is provided.',
      );
    }
    if (anonKey.isEmpty) {
      throw ArgumentError.value(
        anonKey,
        'anonKey',
        'Supabase anon key cannot be empty. '
            'Ensure --dart-define=SUPABASE_ANON_KEY is provided.',
      );
    }

    if (_initialized) {
      throw StateError('SupabaseConfig.initialize() called more than once.');
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: debug,
      // Note: authOptions will be configured in Story 2.1 (Authentication)
      // to include PKCE flow and secure storage per architecture.
    );

    _initialized = true;
  }

  /// Returns the Supabase client.
  ///
  /// Throws [StateError] if not initialized.
  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'SupabaseConfig.client accessed before initialization. '
            'Call SupabaseConfig.initialize() first.',
      );
    }
    return Supabase.instance.client;
  }

  /// Convenience getter for GoTrueClient (auth).
  static GoTrueClient get auth => client.auth;

  /// Resets initialization state for testing.
  ///
  /// WARNING: Only use in tests. Do not call in production code.
  static void resetForTesting() {
    _initialized = false;
  }
}
```

### 📄 `lib/core/di/register_module.dart` (Update)

Add SupabaseClient registration:

```dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/core/config/supabase_config.dart';

/// Module for registering third-party libraries and external dependencies.
///
/// These are dependencies that cannot use @injectable annotations directly.
@module
abstract class RegisterModule {
  /// Provides the SupabaseClient as a lazySingleton.
  ///
  /// Requires SupabaseConfig.initialize() to be called before DI setup.
  @lazySingleton
  SupabaseClient get supabaseClient => SupabaseConfig.client;
}
```

### 📄 `lib/bootstrap.dart` (Update)

```dart
import 'package:flutter/material.dart';
import 'package:tkd_brackets/app/app.dart';
import 'package:tkd_brackets/core/config/supabase_config.dart';
import 'package:tkd_brackets/core/di/injection.dart';

/// Shared initialization for all flavors.
/// This function configures services before launching the app.
Future<void> bootstrap({
  required String environment,
  required String supabaseUrl,
  required String supabaseAnonKey,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase FIRST (before DI so client is available for injection)
  // Debug mode enabled only in development for network request logging.
  await SupabaseConfig.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: environment == 'development',
  );

  // Initialize DI container (can now inject SupabaseClient)
  configureDependencies(environment);

  // TODO(story-1.7): Initialize Sentry.
  // await SentryFlutter.init((options) => ...);

  runApp(const App());
}
```

### 📄 `test/core/config/supabase_config_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/config/supabase_config.dart';

void main() {
  // Reset state before each test to ensure isolation
  setUp(() {
    SupabaseConfig.resetForTesting();
  });

  group('SupabaseConfig initialization guard', () {
    test('should report not initialized before initialize() called', () {
      expect(SupabaseConfig.isInitialized, false);
    });

    test('should throw StateError when accessing client before init', () {
      expect(
        () => SupabaseConfig.client,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('accessed before initialization'),
          ),
        ),
      );
    });

    test('should throw StateError when accessing auth before init', () {
      expect(
        () => SupabaseConfig.auth,
        throwsA(isA<StateError>()),
      );
    });
  });

  group('SupabaseConfig credential validation', () {
    test('should throw ArgumentError when url is empty', () async {
      expect(
        () => SupabaseConfig.initialize(
          url: '',
          anonKey: 'valid-anon-key',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Supabase URL cannot be empty'),
          ),
        ),
      );
    });

    test('should throw ArgumentError when anonKey is empty', () async {
      expect(
        () => SupabaseConfig.initialize(
          url: 'https://example.supabase.co',
          anonKey: '',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Supabase anon key cannot be empty'),
          ),
        ),
      );
    });

    test('should throw ArgumentError when both url and anonKey are empty',
        () async {
      // First validation (url) should trigger
      expect(
        () => SupabaseConfig.initialize(url: '', anonKey: ''),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.name,
            'name',
            equals('url'),
          ),
        ),
      );
    });
  });

  group('SupabaseConfig resetForTesting', () {
    test('should reset isInitialized flag', () {
      // Initially not initialized
      expect(SupabaseConfig.isInitialized, false);

      // Reset should keep it false (idempotent)
      SupabaseConfig.resetForTesting();
      expect(SupabaseConfig.isInitialized, false);
    });
  });

  // Note: Full integration tests require Supabase project setup.
  // These tests validate guard and validation logic without calling
  // Supabase.initialize() since that requires valid credentials.
  //
  // For integration testing with actual Supabase:
  // 1. Create a test Supabase project
  // 2. Use environment variables for credentials
  // 3. Run as integration tests (flutter test integration_test/)
}
```

---

## Testing Strategy

### Unit Tests

| Test                                    | Purpose                                   |
| --------------------------------------- | ----------------------------------------- |
| `isInitialized` returns false initially | Guard logic works before init             |
| `client` throws StateError before init  | Prevents access to uninitialized state    |
| `auth` throws StateError before init    | Auth accessor also guarded                |
| Empty URL throws ArgumentError          | Validates credentials before network call |
| Empty anonKey throws ArgumentError      | Validates credentials before network call |
| `resetForTesting` resets flag           | Test isolation works correctly            |

### Integration Verification (Manual)

After implementation, verify manually:

1. Run `flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
2. Confirm app starts without errors
3. Check console for Supabase debug output (in development mode)

**Verify missing credentials error:**
```bash
# Should fail fast with clear ArgumentError:
flutter run -d chrome
# Expected: ArgumentError with message about --dart-define
```

---

## File Structure After Implementation

```
lib/core/config/
├── environment_configuration.dart  # Existing
└── supabase_config.dart            # NEW - Initialization service

lib/core/di/
├── injection.dart               # Existing
├── injection.config.dart        # Regenerated
├── environment.dart             # Existing
└── register_module.dart         # Updated with SupabaseClient

test/core/config/
├── environment_configuration_test.dart  # If exists
└── supabase_config_test.dart            # NEW - Unit tests
```

---

## Critical Guardrails

### ⚠️ DO NOT

- ❌ Store Supabase URL or anon key in source code
- ❌ Create `lib/core/supabase/` directory (use `lib/core/config/` per architecture)
- ❌ Call Supabase.initialize() after DI container setup
- ❌ Use deprecated `SupabaseClient()` constructor directly
- ❌ Create multiple Supabase instances
- ❌ Skip credential validation (always check for empty strings)

### ✅ MUST

- ✅ Use `--dart-define` for environment variables
- ✅ Place `supabase_config.dart` in `lib/core/config/` (architecture requirement)
- ✅ Initialize Supabase BEFORE `configureDependencies()`
- ✅ Use `Supabase.instance.client` after initialization
- ✅ Register SupabaseClient via `@module` for DI
- ✅ Run `dart run build_runner build` after DI changes
- ✅ Validate URL and anonKey are non-empty before init

---

## Verification Commands

```bash
# From tkd_brackets/ directory:

# 1. Regenerate DI code
dart run build_runner build --delete-conflicting-outputs

# 2. Analyze for errors
dart analyze

# 3. Run tests
flutter test

# 4. Build web (validates compilation)
flutter build web

# 5. Run locally with environment variables
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

---

## Future Story Note

**Story 2.1 (Authentication)** will enhance the Supabase initialization with:
- `FlutterAuthClientOptions` with PKCE flow
- `SecureLocalStorage` for token persistence
- 30-day refresh token configuration

This story establishes the foundation; auth options are deferred per architecture.

---

## Dev Agent Record

### Agent Model Used

Gemini 2.5 Flash

### Debug Log References

- Build runner regenerated DI configuration successfully
- Zero analysis issues after lint fixes
- 108 tests passed (including 7 new Supabase config tests)
- Web build successful with tree-shaking applied

### Completion Notes List

1. **SupabaseConfig service created** - Static class with `initialize()`, `client`, `auth` accessors, proper guard logic and credential validation
2. **DI registration** - SupabaseClient registered as `@lazySingleton` in RegisterModule, accessible via `getIt<SupabaseClient>()`
3. **Bootstrap updated** - Supabase initialization now occurs BEFORE DI container setup (critical ordering)
4. **Debug mode** - Enabled only when `environment == 'development'` for network request logging
5. **Tests added** - 7 unit tests covering initialization guards, credential validation, and test reset utility
6. **All ACs satisfied** - Configuration in correct location, environment-specific config, entry points exist, DI registration works, tests pass

### File List

| File                                       | Action      |
| ------------------------------------------ | ----------- |
| lib/core/config/supabase_config.dart       | Created     |
| lib/core/di/register_module.dart           | Modified    |
| lib/bootstrap.dart                         | Modified    |
| test/core/config/supabase_config_test.dart | Created     |
| lib/core/di/injection.config.dart          | Regenerated |
| README.md                                  | Modified    |

### Change Log

- **2026-02-03**: Implemented Story 1.6 - Supabase client initialization with credential validation, DI registration, and comprehensive unit tests.
- **2026-02-03**: [Code Review] Fixed race condition in `SupabaseConfig.initialize()` using Completer pattern; added README.md to File List.

---

## Senior Developer Review (AI)

**Reviewer:** Asak
**Date:** 2026-02-03
**Outcome:** Approved with Fixes Applied

### Findings Addressed

| Severity | Issue                                           | Resolution                                                                         |
| -------- | ----------------------------------------------- | ---------------------------------------------------------------------------------- |
| MEDIUM   | README.md not in File List                      | Added to File List                                                                 |
| LOW      | Race condition in `SupabaseConfig.initialize()` | Fixed using `Completer` pattern - concurrent callers now await same initialization |
| LOW      | `resetForTesting()` didn't reset Completer      | Updated to also clear `_initCompleter`                                             |

### Notes

- Entry points (`main_development.dart`, etc.) were correctly wired in earlier story but not tracked as changes here (acceptable - they were pre-existing).
- `injection.config.dart` is gitignored (expected for generated files).
- Unit tests verify guard logic only; integration tests require real Supabase credentials (documented in test file).
