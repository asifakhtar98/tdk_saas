# Story 1.1: Project Scaffold & Clean Architecture Setup

Status: ready-for-dev

## Story

As a **developer**,
I want **a properly structured Flutter project with Clean Architecture layers**,
So that **all future features have a consistent, maintainable structure to build upon**.

## Acceptance Criteria

1. **Given** the project needs to be created, **When** I run `flutter create` and configure the project structure, **Then** the following directory structure exists:
   ```
   lib/
   ├── core/
   │   ├── algorithms/
   │   ├── constants/
   │   ├── error/
   │   ├── extensions/
   │   ├── router/
   │   └── utils/
   ├── features/
   │   └── (empty, ready for feature folders)
   ├── app/
   │   └── app.dart
   └── main_development.dart
   ```

2. **Given** the project is configured, **When** I examine pubspec.yaml, **Then** it contains all verified dependencies from the package research.

3. **Given** the project is configured, **When** I examine analysis_options.yaml, **Then** it includes `very_good_analysis` rules.

4. **Given** the project is complete, **When** I run `flutter build web`, **Then** the project builds without errors.

## Tasks / Subtasks

- [ ] **Task 1: Create Flutter Project (AC: #1, #4)**
  - [ ] Run `flutter create tkd_brackets --platforms web --empty` in workspace root (`/Users/asak/Documents/dev/proj/personal/taekwondo_fix/`)
  - [ ] Verify project creates successfully with web platform only
  - [ ] Test basic `flutter build web` works on empty shell

- [ ] **Task 2: Configure pubspec.yaml with Required Dependencies (AC: #2)**
  - [ ] Update pubspec.yaml with project metadata (name, description, version)
  - [ ] Add environment SDK constraints (see Dev Notes)
  - [ ] Add core runtime dependencies (exact versions in Dev Notes)
  - [ ] Add dev dependencies for code generation
  - [ ] Add asset folder declarations
  - [ ] Run `flutter pub get` to verify all dependencies resolve

- [ ] **Task 3: Configure analysis_options.yaml (AC: #3)**
  - [ ] Add `very_good_analysis` as analysis base
  - [ ] Configure project-specific lint rule overrides
  - [ ] Exclude generated files from analysis

- [ ] **Task 4: Create Clean Architecture Directory Structure (AC: #1)**
  - [ ] Create `lib/core/` subdirectories (see exact structure in Dev Notes)
  - [ ] Create `lib/features/` with `.gitkeep`
  - [ ] Create `lib/app/` with `app.dart`
  - [ ] Create `lib/database/` structure for Drift
  - [ ] Create entry points (main_development.dart, main_staging.dart, main_production.dart)
  - [ ] Create `lib/injection.dart` placeholder (required for Story 1.2)

- [ ] **Task 5: Create Core Error Handling Files (AC: #1)**
  - [ ] Create `lib/core/error/failures.dart` with Failure hierarchy
  - [ ] Create `lib/core/error/exceptions.dart` with Exception types

- [ ] **Task 6: Setup Configuration Files (AC: #4)**
  - [ ] Create `.build.yaml` with injectable, go_router_builder, drift_dev configs
  - [ ] Create `.gitignore` with Flutter/Dart exclusions
  - [ ] Create `.env.example` template for environment variables
  - [ ] Verify `dart run build_runner build` executes without errors

- [ ] **Task 7: Create Bootstrap and App Configuration (AC: #4)**
  - [ ] Create `lib/bootstrap.dart` for shared app initialization
  - [ ] Create `lib/app/app.dart` with MaterialApp shell
  - [ ] Create `lib/core/theme/app_theme.dart` with M3 theming
  - [ ] Create `lib/core/config/environment_configuration.dart` placeholder
  - [ ] Ensure app launches successfully with `flutter run -d chrome`

- [ ] **Task 8: Configure Web Assets (AC: #4)**
  - [ ] Update `web/index.html` with proper title and meta tags
  - [ ] Update `web/manifest.json` with app name and theme color

- [ ] **Task 9: Create Test Directory Structure**
  - [ ] Mirror `lib/` structure in `test/`
  - [ ] Create `test/helpers/` for shared test utilities
  - [ ] Add placeholder test file for verification

- [ ] **Task 10: Create Project Documentation**
  - [ ] Create `README.md` with project overview and setup instructions

- [ ] **Task 11: Final Verification (AC: #4)**
  - [ ] Run `dart analyze` with zero issues
  - [ ] Run `flutter build web` successfully
  - [ ] Run `flutter test` (placeholder tests pass)

## Dev Notes

### Project Location

**IMPORTANT:** Create the Flutter project in the workspace root:
```
/Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/
```

### Technical Stack (MANDATORY VERSIONS)

**pubspec.yaml - Complete Configuration:**
```yaml
name: tkd_brackets
description: Tournament bracket management for Taekwondo competitions with offline-first capability.
version: 0.1.0+1
repository: https://github.com/YOUR_ORG/tkd_brackets
publish_to: none

environment:
  sdk: ">=3.5.0 <4.0.0"
  flutter: ">=3.24.0"

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^9.0.0
  bloc: ^9.0.0
  equatable: ^2.0.7
  
  # Dependency Injection
  get_it: ^8.0.3
  injectable: ^2.5.0
  
  # Navigation
  go_router: ^15.1.1
  
  # Backend Integration
  supabase_flutter: ^2.8.4
  
  # Local Database (Offline-First)
  drift: ^2.23.1
  drift_flutter: ^0.2.4
  
  # Error Tracking
  sentry_flutter: ^8.12.0
  
  # Error Handling (Functional)
  fpdart: ^1.1.1
  
  # Network Utilities
  connectivity_plus: ^6.1.3
  internet_connection_checker_plus: ^2.6.0
  
  # Forms (for future use)
  flutter_form_builder: ^9.5.1
  form_builder_validators: ^11.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.14
  injectable_generator: ^2.6.3
  go_router_builder: ^2.9.0
  drift_dev: ^2.23.1
  
  # Linting
  very_good_analysis: ^7.0.0
  
  # Testing
  bloc_test: ^9.1.7
  mocktail: ^1.0.4

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/fonts/
    - assets/l10n/
```

### Project Structure (EXACT LAYOUT - Copy This)

```
tkd_brackets/
├── lib/
│   ├── main_development.dart      # Dev entry point
│   ├── main_staging.dart          # Staging entry point  
│   ├── main_production.dart       # Production entry point
│   ├── bootstrap.dart             # Shared initialization
│   ├── injection.dart             # @InjectableInit placeholder
│   │
│   ├── app/
│   │   └── app.dart               # Root MaterialApp widget
│   │
│   ├── core/
│   │   ├── algorithms/            # Bracket/seeding algorithms (future)
│   │   │   └── .gitkeep
│   │   ├── config/
│   │   │   └── environment_configuration.dart
│   │   ├── constants/
│   │   │   └── app_constants.dart
│   │   ├── error/
│   │   │   ├── failures.dart      # Failure hierarchy (domain layer)
│   │   │   └── exceptions.dart    # Exception types (data layer)
│   │   ├── extensions/
│   │   │   └── .gitkeep
│   │   ├── network/
│   │   │   └── .gitkeep           # For network_information.dart (Story 1.4)
│   │   ├── router/                # NOTE: "router" not "routing" per architecture
│   │   │   └── app_router.dart    # GoRouter placeholder
│   │   ├── services/
│   │   │   └── .gitkeep
│   │   ├── theme/
│   │   │   └── app_theme.dart     # M3 theme configuration
│   │   ├── utils/
│   │   │   └── .gitkeep
│   │   └── widgets/
│   │       └── .gitkeep
│   │
│   ├── features/
│   │   └── .gitkeep               # Empty, ready for features
│   │
│   └── database/
│       └── .gitkeep               # Drift tables go here
│
├── test/
│   ├── helpers/
│   │   └── test_helpers.dart
│   ├── core/
│   │   └── .gitkeep
│   └── features/
│       └── .gitkeep
│
├── web/
│   ├── index.html                 # Update title and meta tags
│   ├── manifest.json
│   └── favicon.png
│
├── assets/
│   ├── images/
│   │   └── .gitkeep
│   ├── fonts/
│   │   └── .gitkeep
│   └── l10n/
│       └── app_en.arb
│
├── pubspec.yaml
├── analysis_options.yaml
├── .build.yaml
├── .gitignore
├── .env.example
└── README.md
```

### Naming Conventions (MANDATORY)

| Element        | Pattern               | Example                    |
| -------------- | --------------------- | -------------------------- |
| **Files**      | `snake_case.dart`     | `app_router.dart`          |
| **Classes**    | `PascalCase`, verbose | `EnvironmentConfiguration` |
| **Failures**   | `{Category}Failure`   | `ServerConnectionFailure`  |
| **Exceptions** | `{Category}Exception` | `ServerException`          |

### Code Files (COPY-PASTE READY)

---

**📄 `lib/main_development.dart`:**
```dart
import 'package:tkd_brackets/bootstrap.dart';

void main() {
  bootstrap(
    environment: 'development',
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
}
```

---

**📄 `lib/main_staging.dart`:**
```dart
import 'package:tkd_brackets/bootstrap.dart';

void main() {
  bootstrap(
    environment: 'staging',
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
}
```

---

**📄 `lib/main_production.dart`:**
```dart
import 'package:tkd_brackets/bootstrap.dart';

void main() {
  bootstrap(
    environment: 'production',
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
}
```

---

**📄 `lib/bootstrap.dart`:**
```dart
import 'package:flutter/material.dart';
import 'package:tkd_brackets/app/app.dart';

/// Shared initialization for all flavors.
/// This function configures services before launching the app.
Future<void> bootstrap({
  required String environment,
  required String supabaseUrl,
  required String supabaseAnonKey,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Initialize DI container (Story 1.2)
  // await configureDependencies(environment);
  
  // TODO: Initialize Supabase (Story 1.6)
  // await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  
  // TODO: Initialize Sentry (Story 1.7)
  // await SentryFlutter.init((options) => ...);
  
  runApp(const App());
}
```

---

**📄 `lib/injection.dart`:**
```dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

// TODO: Uncomment after running build_runner in Story 1.2
// import 'package:tkd_brackets/injection.config.dart';

final GetIt getIt = GetIt.instance;

/// Configures the dependency injection container.
/// Call this from bootstrap.dart before runApp().
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies(String environment) async {
  // TODO: Uncomment after running build_runner in Story 1.2
  // getIt.init(environment: environment);
}
```

---

**📄 `lib/app/app.dart`:**
```dart
import 'package:flutter/material.dart';
import 'package:tkd_brackets/core/theme/app_theme.dart';

/// Root application widget.
/// Configures MaterialApp with theming and routing.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TKD Brackets',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      // TODO: Replace with GoRouter in Story 1.3
      home: const Scaffold(
        body: Center(
          child: Text('TKD Brackets - Foundation Setup Complete'),
        ),
      ),
    );
  }
}
```

---

**📄 `lib/core/theme/app_theme.dart`:**
```dart
import 'package:flutter/material.dart';

/// TKD Brackets theme configuration using Material Design 3.
/// 
/// Brand Colors:
/// - Primary: Navy (#1E3A5F) - Trust, professionalism
/// - Secondary: Gold (#D4AF37) - Excellence, achievement
class AppTheme {
  AppTheme._();

  static const _navyPrimary = Color(0xFF1E3A5F);
  static const _goldSecondary = Color(0xFFD4AF37);
  
  /// Light theme configuration.
  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _navyPrimary,
      secondary: _goldSecondary,
      brightness: Brightness.light,
    ),
  );
  
  /// Dark theme configuration.
  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _navyPrimary,
      secondary: _goldSecondary,
      brightness: Brightness.dark,
    ),
  );
}
```

---

**📄 `lib/core/error/failures.dart`:**
```dart
import 'package:equatable/equatable.dart';

/// Base failure class for all domain-level errors.
/// All use cases return Either<Failure, T>.
/// 
/// Failures are user-facing errors that bubble up from the domain layer.
/// For data-layer errors, use [Exception] types instead.
abstract class Failure extends Equatable {
  /// Message safe to display to end users.
  final String userFriendlyMessage;
  
  /// Technical details for logging/debugging (not shown to users).
  final String? technicalDetails;

  const Failure({
    required this.userFriendlyMessage,
    this.technicalDetails,
  });

  @override
  List<Object?> get props => [userFriendlyMessage, technicalDetails];
}

// ═══════════════════════════════════════════════════════════════════════════
// Network Failures
// ═══════════════════════════════════════════════════════════════════════════

class ServerConnectionFailure extends Failure {
  const ServerConnectionFailure({
    super.userFriendlyMessage = 'Unable to connect to server. Please check your internet connection.',
    super.technicalDetails,
  });
}

class ServerResponseFailure extends Failure {
  final int? statusCode;

  const ServerResponseFailure({
    required super.userFriendlyMessage,
    super.technicalDetails,
    this.statusCode,
  });

  @override
  List<Object?> get props => [userFriendlyMessage, technicalDetails, statusCode];
}

// ═══════════════════════════════════════════════════════════════════════════
// Local Storage Failures
// ═══════════════════════════════════════════════════════════════════════════

class LocalCacheAccessFailure extends Failure {
  const LocalCacheAccessFailure({
    super.userFriendlyMessage = 'Unable to access local storage.',
    super.technicalDetails,
  });
}

class LocalCacheWriteFailure extends Failure {
  const LocalCacheWriteFailure({
    super.userFriendlyMessage = 'Unable to save data locally.',
    super.technicalDetails,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Sync Failures
// ═══════════════════════════════════════════════════════════════════════════

class DataSynchronizationFailure extends Failure {
  const DataSynchronizationFailure({
    super.userFriendlyMessage = 'Unable to sync data. Changes saved locally.',
    super.technicalDetails,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Validation Failures
// ═══════════════════════════════════════════════════════════════════════════

class InputValidationFailure extends Failure {
  final Map<String, String> fieldErrors;

  const InputValidationFailure({
    required super.userFriendlyMessage,
    required this.fieldErrors,
  });

  @override
  List<Object?> get props => [userFriendlyMessage, fieldErrors];
}

// ═══════════════════════════════════════════════════════════════════════════
// Authentication Failures
// ═══════════════════════════════════════════════════════════════════════════

class AuthenticationSessionExpiredFailure extends Failure {
  const AuthenticationSessionExpiredFailure({
    super.userFriendlyMessage = 'Your session has expired. Please sign in again.',
  });
}

class AuthorizationPermissionDeniedFailure extends Failure {
  const AuthorizationPermissionDeniedFailure({
    super.userFriendlyMessage = 'You do not have permission to perform this action.',
  });
}
```

---

**📄 `lib/core/error/exceptions.dart`:**
```dart
/// Base exception for data layer errors.
/// These are thrown by data sources and caught by repositories.
/// Repositories convert exceptions to [Failure] types for the domain layer.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

// ═══════════════════════════════════════════════════════════════════════════
// Server Exceptions (Remote Data Source)
// ═══════════════════════════════════════════════════════════════════════════

class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    required super.message,
    super.code,
    super.originalError,
    this.statusCode,
  });
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network connection unavailable',
    super.code,
    super.originalError,
  });
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Authentication required',
    super.code = '401',
    super.originalError,
  });
}

class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'Access denied',
    super.code = '403',
    super.originalError,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Cache Exceptions (Local Data Source)
// ═══════════════════════════════════════════════════════════════════════════

class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.originalError,
  });
}

class CacheReadException extends CacheException {
  const CacheReadException({
    super.message = 'Failed to read from local cache',
    super.code,
    super.originalError,
  });
}

class CacheWriteException extends CacheException {
  const CacheWriteException({
    super.message = 'Failed to write to local cache',
    super.code,
    super.originalError,
  });
}
```

---

**📄 `lib/core/config/environment_configuration.dart`:**
```dart
/// Environment configuration holder.
/// Values are passed from main_*.dart entry points.
class EnvironmentConfiguration {
  final String environment;
  final String supabaseUrl;
  final String supabaseAnonKey;

  const EnvironmentConfiguration({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  bool get isDevelopment => environment == 'development';
  bool get isStaging => environment == 'staging';
  bool get isProduction => environment == 'production';
}
```

---

**📄 `lib/core/constants/app_constants.dart`:**
```dart
/// Application-wide constants.
abstract class AppConstants {
  /// Application display name.
  static const String appName = 'TKD Brackets';
  
  /// Minimum supported participants for a bracket.
  static const int minBracketParticipants = 2;
  
  /// Maximum participants per bracket (free tier).
  static const int maxParticipantsFreeTier = 32;
  
  /// Maximum rings per tournament.
  static const int maxRingsPerTournament = 20;
}
```

---

**📄 `lib/core/router/app_router.dart`:**
```dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

/// Application router configuration.
/// TODO: Implement type-safe routes with go_router_builder in Story 1.3.
class AppRouter {
  AppRouter._();

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
```

---

**📄 `analysis_options.yaml`:**
```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.config.dart"
    - "build/**"
    - ".dart_tool/**"

linter:
  rules:
    public_member_api_docs: false  # Disable for MVP velocity
```

---

**📄 `.build.yaml`:**
```yaml
targets:
  $default:
    builders:
      injectable_generator|injectable_builder:
        enabled: true
        generate_for:
          include:
            - lib/**
      go_router_builder|go_router_builder:
        enabled: true
        generate_for:
          include:
            - lib/**
      drift_dev|drift_dev:
        enabled: true
        generate_for:
          include:
            - lib/**
```

---

**📄 `.gitignore`:**
```gitignore
# Dart/Flutter
.dart_tool/
.packages
build/
*.iml
*.log

# Generated files
*.g.dart
*.freezed.dart
*.config.dart
*.mocks.dart

# IDE
.idea/
*.iml
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json

# macOS
.DS_Store
*.swp
*.swo

# Environment
.env
.env.local
.env.*.local

# Coverage
coverage/

# Misc
pubspec.lock
```

---

**📄 `.env.example`:**
```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# Sentry Configuration (optional for development)
SENTRY_DSN=https://your-sentry-dsn
```

---

**📄 `README.md`:**
```markdown
# TKD Brackets

Tournament bracket management for Taekwondo competitions with offline-first capability.

## Getting Started

### Prerequisites

- Flutter SDK >= 3.24.0
- Dart SDK >= 3.5.0

### Setup

1. Clone the repository
2. Copy `.env.example` to `.env` and configure your environment variables
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Generate code:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
5. Run the app:
   ```bash
   flutter run -d chrome -t lib/main_development.dart
   ```

## Architecture

This project follows Clean Architecture with three layers:
- **Presentation**: UI, BLoCs, Widgets
- **Domain**: Entities, Use Cases, Repository Interfaces
- **Data**: Models, Data Sources, Repository Implementations

## Project Structure

```
lib/
├── app/           # Root app configuration
├── core/          # Shared infrastructure
├── features/      # Feature modules
└── database/      # Drift database definitions
```
```

---

**📄 `test/helpers/test_helpers.dart`:**
```dart
/// Shared test utilities and helpers.
/// 
/// Add common mocks, fixtures, and helper functions here.
library;

// Example: Common test setup
void setupTestDependencies() {
  // TODO: Configure test DI container
}
```

---

**📄 `web/index.html` Updates:**
Update these sections in the generated `web/index.html`:
```html
<title>TKD Brackets</title>
<meta name="description" content="Tournament bracket management for Taekwondo">
<meta name="theme-color" content="#1E3A5F">
```

---

### Anti-Patterns to AVOID

❌ **DO NOT** abbreviate class names (use `Implementation` not `Impl`)
❌ **DO NOT** use generic file names like `utils.dart` or `helpers.dart` without prefix
❌ **DO NOT** put business logic in `core/` — that's for infrastructure only
❌ **DO NOT** add dependencies not listed above without explicit justification
❌ **DO NOT** create `lib/src/` structure — we use feature-based organization
❌ **DO NOT** use `routing/` — the architecture specifies `router/`

### Verification Commands

After all tasks complete, run these commands and ensure zero errors:

```bash
# Navigate to project
cd tkd_brackets

# Verify dependencies resolve
flutter pub get

# Verify build_runner works (may have no output yet)
dart run build_runner build --delete-conflicting-outputs

# Verify linting passes
dart analyze

# Verify web build succeeds
flutter build web

# Verify tests pass (placeholder)
flutter test

# Verify app runs
flutter run -d chrome -t lib/main_development.dart
```

### References

- [Source: architecture.md#Starter-Template-Evaluation] — Flutter create command, initialization sequence
- [Source: architecture.md#Project-Structure-&-Boundaries] — Complete directory structure specification
- [Source: architecture.md#Implementation-Patterns-&-Consistency-Rules] — Naming conventions, failure patterns
- [Source: architecture.md#Core-Architectural-Decisions] — Error handling with fpdart Either pattern
- [Source: epics.md#Story-1.1] — Acceptance criteria for this story

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Change Log

| Date | Change | Rationale |
| ---- | ------ | --------- |

### Completion Notes List

### File List
