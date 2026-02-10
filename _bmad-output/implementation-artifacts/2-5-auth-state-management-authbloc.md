# Story 2.5: Auth State Management (AuthBloc)

Status: backlog

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

**As a** developer,
**I want** authentication state managed via BLoC,
**So that** the UI can react to auth state changes consistently.

## Acceptance Criteria

- [ ] **AC1**: `AuthenticationBloc` handles events: `AuthenticationCheckRequested`, `AuthenticationUserChanged` (internal), `AuthenticationSignOutRequested`
- [ ] **AC2**: `AuthenticationState` includes: `initial`, `checkInProgress`, `authenticated(UserEntity)`, `unauthenticated`, `signOutInProgress`, `authenticationFailure(Failure)`
- [ ] **AC3**: Auth state persists across app restarts (session recovery via `getCurrentAuthenticatedUser`)
- [ ] **AC4**: Logout clears Supabase session but preserves local demo data
- [ ] **AC5**: `GetCurrentUserUseCase` exists and wraps `AuthRepository.getCurrentAuthenticatedUser()`
- [ ] **AC6**: `SignOutUseCase` exists and wraps `AuthRepository.signOut()`
- [ ] **AC7**: `AuthenticationBloc` subscribes to `AuthRepository.authStateChanges` stream
- [ ] **AC8**: `AuthenticationBloc` is registered as `@lazySingleton` in DI
- [ ] **AC9**: `App` widget wraps with `BlocProvider.value` for `AuthenticationBloc` and dispatches initial check in `initState`
- [ ] **AC10**: Router redirect guard uses `AuthenticationBloc` state for auth-based navigation with `refreshListenable`
- [ ] **AC11**: Unit tests verify all state transitions using `bloc_test`
- [ ] **AC12**: `flutter analyze` passes with zero errors
- [ ] **AC13**: `dart run build_runner build` completes successfully
- [ ] **AC14**: Auth barrel file updated with all new exports

> **⚠️ EPIC AC DEVIATION:** The epics (Story 2.5 AC) list events `AuthSignUpRequested` and `AuthSignInRequested`, but these are **intentionally omitted**. The `AuthenticationBloc` manages *global auth state observation*, NOT auth *flows*. Sign-up/sign-in are per-screen flows handled by their own BLoCs (e.g., `SignInBloc`) in the presentation layer. The `AuthenticationBloc` reacts to the *outcome* of those flows via the `authStateChanges` stream subscription. This separation follows Clean Architecture — the `AuthenticationBloc` is a *state observer*, not a *flow orchestrator*.

---

## Project Context

> **⚠️ CRITICAL: All paths are relative to `tkd_brackets/`**
>
> Project root: `/Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/`
>
> When creating files, always work within `tkd_brackets/lib/`

---

## Dependencies

### Upstream (Required) ✅

| Story                        | Provides                                                                           |
| ---------------------------- | ---------------------------------------------------------------------------------- |
| 2.1 Auth Feature Structure   | Feature directory structure, `UseCase<T, Params>` base class                       |
| 2.2 User Entity & Repository | `UserEntity`, `UserModel`, local/remote datasources                                |
| 2.3 Email Magic Link Sign Up | `SupabaseAuthDatasource`, `AuthRepository` interface, auth failures                |
| 2.4 Email Magic Link Sign In | `verifyMagicLinkOtp`, `getCurrentAuthenticatedUser`, `authStateChanges`, `signOut` |
| 1.6 Supabase Client          | `SupabaseClient` instance registered in DI                                         |
| 1.4 Error Handling           | `Failure` hierarchy in `core/error/failures.dart`                                  |

### Downstream (Enables)

- Story 2.6-2.10: Organization management features (depend on authenticated user)
- All presentation layer stories (consume `AuthenticationBloc` for auth-aware UI)

---

## ⚠️ CRITICAL: What Already Exists

> **DO NOT recreate these - they are implemented and working!**

### UseCase Base Class (`lib/core/usecases/use_case.dart`)

```dart
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

@immutable
class NoParams {
  const NoParams();
}
```

### AuthRepository Interface (`lib/features/auth/domain/repositories/auth_repository.dart`)

```dart
abstract class AuthRepository {
  Future<Either<Failure, Unit>> sendSignUpMagicLink({required String email});
  Future<Either<Failure, Unit>> sendSignInMagicLink({required String email});
  Future<Either<Failure, UserEntity>> verifyMagicLinkOtp({
    required String email,
    required String token,
  });
  Future<Either<Failure, Unit>> signOut();
  Future<Either<Failure, UserEntity>> getCurrentAuthenticatedUser();
  Stream<Either<Failure, UserEntity?>> get authStateChanges;
}
```

### AuthRepositoryImplementation (`lib/features/auth/data/repositories/auth_repository_implementation.dart`)

Already implements all methods above including:
- `getCurrentAuthenticatedUser()` → checks `currentUser` from datasource, tries local cache first, then remote, returns `UserEntity`
- `signOut()` → calls `_authDatasource.signOut()`, maps errors
- `authStateChanges` → listens to `_authDatasource.onAuthStateChange`, maps to `Either<Failure, UserEntity?>`

> **⚠️ NOTE:** `signOut()` only clears the Supabase session. It does NOT clear the local Drift database. Demo data and cached users are preserved.

### UserEntity (`lib/features/auth/domain/entities/user_entity.dart`)

```dart
@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String email,
    required String displayName,
    required String organizationId,
    required UserRole role,
    required bool isActive,
    required DateTime createdAt,
    String? avatarUrl,
    DateTime? lastSignInAt,  // NOTE: lastSignInAt NOT lastLoginAt
  }) = _UserEntity;
}
```

### Auth Failure Classes (`lib/core/error/auth_failures.dart`)

```dart
class MagicLinkSendFailure extends Failure { ... }
class InvalidEmailFailure extends Failure { ... }
class RateLimitExceededFailure extends Failure { ... }
class InvalidTokenFailure extends Failure { ... }
class ExpiredTokenFailure extends Failure { ... }
class UserNotFoundFailure extends Failure { ... }
class OtpVerificationFailure extends Failure { ... }
class SignOutFailure extends Failure { ... }
```

### SupabaseAuthDatasource (`lib/features/auth/data/datasources/supabase_auth_datasource.dart`)

```dart
abstract class SupabaseAuthDatasource {
  Future<void> sendMagicLink({required String email, required bool shouldCreateUser, String? redirectTo});
  Future<AuthResponse> verifyOtp({required String email, required String token, required OtpType type});
  User? get currentUser;
  Stream<AuthState> get onAuthStateChange;
  Future<void> signOut();
}
```

### Existing Presentation BLoC Directory (`lib/features/auth/presentation/bloc/`)

Currently contains only `.gitkeep`. This is where the BLoC files go.

### DI Setup (`lib/core/di/injection.dart`)

```dart
final GetIt getIt = GetIt.instance;

@InjectableInit(initializerName: 'init', preferRelativeImports: true, asExtension: true)
void configureDependencies(String environment) => getIt.init(environment: environment);
```

### App Widget (`lib/app/app.dart`)

```dart
class App extends StatefulWidget { ... }
class _AppState extends State<App> {
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

### Router (`lib/core/router/app_router.dart`)

Contains `TODO(story-2.5)` placeholder in `_redirectGuard` method:
```dart
String? _redirectGuard(BuildContext context, GoRouterState state) {
  final location = state.matchedLocation;
  if (location == '/app' || location == '/app/') {
    return '/dashboard';
  }
  // TODO(story-2.5): Implement auth redirect logic
  return null;
}
```

### Current Barrel File (`lib/features/auth/auth.dart`)

```dart
library;
export 'data/datasources/supabase_auth_datasource.dart';
export 'data/datasources/user_local_datasource.dart';
export 'data/datasources/user_remote_datasource.dart';
export 'data/models/user_model.dart';
export 'data/repositories/auth_repository_implementation.dart';
export 'data/repositories/user_repository_implementation.dart';
export 'domain/entities/user_entity.dart';
export 'domain/repositories/auth_repository.dart';
export 'domain/repositories/user_repository.dart';
export 'domain/usecases/sign_in_with_email_params.dart';
export 'domain/usecases/sign_in_with_email_use_case.dart';
export 'domain/usecases/sign_up_with_email_params.dart';
export 'domain/usecases/sign_up_with_email_use_case.dart';
export 'domain/usecases/verify_magic_link_params.dart';
export 'domain/usecases/verify_magic_link_use_case.dart';
```

### Installed Packages (from `pubspec.yaml`)

- `bloc: ^9.0.0` and `flutter_bloc: ^9.0.0` — already in dependencies
- `bloc_test: ^10.0.0` — already in dev_dependencies
- `freezed_annotation: ^2.4.4` — already in dependencies
- `injectable: ^2.5.0` — already in dependencies

---

## ⚠️ CRITICAL: Architecture Constraints

> **These MUST be followed to prevent code review issues!**

### 1. Naming Conventions (from architecture.md)

- **Event naming**: `{Feature}{Action}Requested` → e.g., `AuthenticationCheckRequested`
- **State naming**: `{Feature}{Status}` → e.g., `AuthenticationCheckInProgress`
- **BLoC class**: `AuthenticationBloc` (NOT `AuthBloc` — use full words, no abbreviations)
- **File naming**: `authentication_bloc.dart`, `authentication_event.dart`, `authentication_state.dart`
- **Use `implementation` not `impl`** in class names

### 2. BLoC Pattern (from architecture.md lines 770-807)

```dart
// Events use freezed with {Feature}{Action}Requested pattern
@freezed
class AuthenticationEvent with _$AuthenticationEvent {
  const factory AuthenticationEvent.checkRequested() = AuthenticationCheckRequested;
  // ...
}

// States use freezed with {Feature}{Status} pattern
@freezed
class AuthenticationState with _$AuthenticationState {
  const factory AuthenticationState.initial() = AuthenticationInitial;
  const factory AuthenticationState.checkInProgress() = AuthenticationCheckInProgress;
  // ...
}
```

### 3. Domain Layer Independence

**❌ NEVER import from data layer in domain usecases or BLoC:**
```dart
// ❌ WRONG
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ CORRECT - Domain depends only on domain interfaces
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
```

### 4. BLoC Registration

- BLoC should be `@lazySingleton` since it manages global auth state
- Use cases injected into BLoC via constructor (injectable handles wiring)

### 5. Presentation → Domain Boundary

- **BLoC calls use cases only** — no direct repository access from BLoC
- Use cases wrap single repository methods with validation

---

## Tasks

### Task 1: Create `GetCurrentUserUseCase`

**File:** `lib/features/auth/domain/usecases/get_current_user_use_case.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';

/// Use case to get the currently authenticated user.
///
/// Checks Supabase session, then local cache, then remote.
/// Returns [UserEntity] if authenticated, [Failure] if not.
@injectable
class GetCurrentUserUseCase
    extends UseCase<UserEntity, NoParams> {
  GetCurrentUserUseCase(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Future<Either<Failure, UserEntity>> call(
    NoParams params,
  ) async {
    return _authRepository.getCurrentAuthenticatedUser();
  }
}
```

---

### Task 2: Create `SignOutUseCase`

**File:** `lib/features/auth/domain/usecases/sign_out_use_case.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';

/// Use case to sign out the current user.
///
/// Clears the Supabase auth session.
/// Does NOT clear local Drift database (demo data preserved).
@injectable
class SignOutUseCase extends UseCase<Unit, NoParams> {
  SignOutUseCase(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    return _authRepository.signOut();
  }
}
```

---

### Task 3: Create `AuthenticationEvent` (Freezed)

**File:** `lib/features/auth/presentation/bloc/authentication_event.dart`

> **⚠️ CRITICAL:** Follow `{Feature}{Action}Requested` naming. Delete `.gitkeep` from `presentation/bloc/`.

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

part 'authentication_event.freezed.dart';

/// Events for [AuthenticationBloc].
///
/// Naming follows architecture convention:
/// `{Feature}{Action}Requested`
@freezed
class AuthenticationEvent with _$AuthenticationEvent {
  /// Check if user has an existing session (app startup).
  const factory AuthenticationEvent.checkRequested() =
      AuthenticationCheckRequested;

  /// **INTERNAL EVENT — DO NOT DISPATCH FROM UI.**
  ///
  /// User authenticated externally (from auth state stream).
  /// Only dispatched by the BLoC's own stream subscription.
  /// UI widgets should NEVER add this event directly.
  const factory AuthenticationEvent.userChanged(
    UserEntity? user,
  ) = AuthenticationUserChanged;

  /// User requested sign out.
  const factory AuthenticationEvent.signOutRequested() =
      AuthenticationSignOutRequested;
}
```

> **⚠️ CRITICAL:** `AuthenticationUserChanged` is an **internal-only** event dispatched by the stream subscription inside `AuthenticationBloc`. It carries the `UserEntity?` from the `authStateChanges` stream. **UI widgets MUST NEVER dispatch this event directly.** If a widget needs to trigger auth state changes, it should use the dedicated sign-in/sign-out BLoC events or the auth flow BLoCs instead.

---

### Task 4: Create `AuthenticationState` (Freezed)

**File:** `lib/features/auth/presentation/bloc/authentication_state.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

part 'authentication_state.freezed.dart';

/// States for [AuthenticationBloc].
///
/// Naming follows architecture convention:
/// `{Feature}{Status}`
@freezed
class AuthenticationState with _$AuthenticationState {
  /// Initial state before any auth check.
  const factory AuthenticationState.initial() =
      AuthenticationInitial;

  /// Auth check is in progress (loading).
  const factory AuthenticationState.checkInProgress() =
      AuthenticationCheckInProgress;

  /// User is authenticated.
  const factory AuthenticationState.authenticated(
    UserEntity user,
  ) = AuthenticationAuthenticated;

  /// User is not authenticated.
  const factory AuthenticationState.unauthenticated() =
      AuthenticationUnauthenticated;

  /// Sign-out is in progress.
  const factory AuthenticationState.signOutInProgress() =
      AuthenticationSignOutInProgress;

  /// Authentication operation failed.
  const factory AuthenticationState.failure(
    Failure failure,
  ) = AuthenticationFailure;
}
```

---

### Task 5: Create `AuthenticationBloc`

**File:** `lib/features/auth/presentation/bloc/authentication_bloc.dart`

> **⚠️ CRITICAL IMPLEMENTATION NOTES:**
> 1. Must be `@lazySingleton` — global auth state shared across app
> 2. Subscribes to `authRepository.authStateChanges` in constructor
> 3. Cancels stream subscription in `close()`
> 4. Calls use cases, NOT repository directly
> 5. `authStateChanges` stream is accessed from repository (not use case) — this is acceptable because stream subscriptions are infrastructure concerns managed by the BLoC layer, and creating a use case just to expose a stream adds complexity without value

```dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_state.dart';

/// BLoC managing global authentication state.
///
/// This is a singleton BLoC that:
/// 1. Checks for existing sessions on startup
/// 2. Listens to auth state changes from Supabase
/// 3. Handles sign-out requests
///
/// Registered as [lazySingleton] because auth state is
/// global and shared across the entire app.
@lazySingleton
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc(
    this._getCurrentUserUseCase,
    this._signOutUseCase,
    this._authRepository,
  ) : super(const AuthenticationState.initial()) {
    on<AuthenticationCheckRequested>(_onCheckRequested);
    on<AuthenticationUserChanged>(_onUserChanged);
    on<AuthenticationSignOutRequested>(
      _onSignOutRequested,
    );

    // Subscribe to auth state changes stream
    _authStateSubscription = _authRepository
        .authStateChanges
        .listen((either) {
      either.fold(
        // On error from stream, we don't crash — just
        // log and keep current state
        (_) {},
        (user) => add(AuthenticationUserChanged(user)),
      );
    });
  }

  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final SignOutUseCase _signOutUseCase;
  final AuthRepository _authRepository;

  StreamSubscription<Either<Failure, UserEntity?>>?
      _authStateSubscription;

  Future<void> _onCheckRequested(
    AuthenticationCheckRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationState.checkInProgress());

    final result = await _getCurrentUserUseCase(
      const NoParams(),
    );

    result.fold(
      (failure) => emit(
        const AuthenticationState.unauthenticated(),
      ),
      (user) => emit(
        AuthenticationState.authenticated(user),
      ),
    );
  }

  Future<void> _onUserChanged(
    AuthenticationUserChanged event,
    Emitter<AuthenticationState> emit,
  ) async {
    final user = event.user;
    if (user != null) {
      emit(AuthenticationState.authenticated(user));
    } else {
      emit(const AuthenticationState.unauthenticated());
    }
  }

  Future<void> _onSignOutRequested(
    AuthenticationSignOutRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationState.signOutInProgress());

    final result = await _signOutUseCase(
      const NoParams(),
    );

    result.fold(
      (failure) => emit(
        AuthenticationState.failure(failure),
      ),
      (_) => emit(
        const AuthenticationState.unauthenticated(),
      ),
    );
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
```

---

### Task 6: Update `App` Widget with `BlocProvider`

**File:** `lib/app/app.dart`

> **⚠️ CRITICAL:** Use `BlocProvider.value` (NOT `create:`). Since `AuthenticationBloc` is a `@lazySingleton` managed by `getIt`, using `BlocProvider` with `create:` would cause it to call `close()` on the BLoC when the provider is removed from the widget tree — permanently closing the singleton. `BlocProvider.value` does NOT manage disposal, which is correct for DI-managed singletons.

> **⚠️ CRITICAL:** Dispatch `AuthenticationCheckRequested` in `initState` (NOT in `build`). Dispatching in `build` would re-dispatch on every rebuild.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/core/router/app_router.dart';
import 'package:tkd_brackets/core/theme/app_theme.dart';
import 'package:tkd_brackets/core/web/web_notification.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_event.dart';

/// Root application widget.
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    // Dispatch initial auth check once, not on every build
    getIt<AuthenticationBloc>().add(
      const AuthenticationEvent.checkRequested(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WebNotificationService.notifyFlutterReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appRouter = getIt<AppRouter>();

    return BlocProvider<AuthenticationBloc>.value(
      value: getIt<AuthenticationBloc>(),
      child: MaterialApp.router(
        title: 'TKD Brackets',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter.router,
      ),
    );
  }
}
```

> **⚠️ WHY `BlocProvider.value`?** `BlocProvider` with `create:` calls `close()` on the BLoC when the provider is removed from the widget tree. For a `@lazySingleton`, this would permanently close the BLoC — subsequent `getIt<AuthenticationBloc>()` calls would return a closed instance. `BlocProvider.value` delegates lifecycle management to `getIt`, which is the correct pattern for DI-managed singletons.

---

### Task 7: Update Router Auth Redirect Guard

**File:** `lib/core/router/app_router.dart`

> **⚠️ CRITICAL:** The router needs:
> 1. Access to `AuthenticationBloc` state for redirects via `getIt<AuthenticationBloc>()`
> 2. `refreshListenable` to re-evaluate redirects when auth state changes
> 3. A `GoRouterRefreshStream` adapter to bridge the BLoC stream to `ChangeNotifier`
>
> Without `refreshListenable`, the router only evaluates redirects on navigation events. Auth state changes (login/logout) would NOT trigger redirects until the user manually navigates.

Replace the existing `_redirectGuard` method, add `GoRouterRefreshStream`, and add necessary imports:

```dart
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
    _subscription =
        stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ... (AppRouter class — modify GoRouter constructor) ...

  late final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: _redirectGuard,
    // ⚠️ CRITICAL: refreshListenable triggers redirect
    // re-evaluation when auth state changes
    refreshListenable: GoRouterRefreshStream(
      getIt<AuthenticationBloc>().stream,
    ),
    observers: _buildObservers(),
    routes: [
      // ... (routes unchanged) ...
    ],
    errorBuilder: _buildErrorPage,
  );

  // ... (existing methods unchanged) ...

  /// Redirect guard with auth state checking.
  String? _redirectGuard(
    BuildContext context,
    GoRouterState state,
  ) {
    final location = state.matchedLocation;

    // Redirect /app routes to dashboard for shell entry
    if (location == '/app' || location == '/app/') {
      return '/dashboard';
    }

    final authState = getIt<AuthenticationBloc>().state;

    // Public routes that don't require auth
    const publicRoutes = ['/', '/demo'];
    final isPublicRoute = publicRoutes.contains(location);

    final isAuthenticated =
        authState is AuthenticationAuthenticated;

    // If authenticated and on public route, go to dashboard
    if (isAuthenticated && isPublicRoute) {
      return '/dashboard';
    }

    // If not authenticated and on protected route, go home
    if (!isAuthenticated &&
        !isPublicRoute &&
        authState is! AuthenticationCheckInProgress &&
        authState is! AuthenticationInitial) {
      return '/';
    }

    return null;
  }
```

> **⚠️ NOTE:** During `AuthenticationInitial` and `AuthenticationCheckInProgress` states, we do NOT redirect. This prevents premature redirects before the initial auth check completes.
>
> **⚠️ IMPORTANT:** `GoRouterRefreshStream` MUST be defined as a **top-level class** in `app_router.dart` (outside `AppRouter`), NOT as a private nested class. This ensures testability and follows Dart conventions.

---

### Task 8: Update Auth Barrel File

**File:** `lib/features/auth/auth.dart`

Add new exports (keep existing, add in sorted order):

```dart
/// Authentication feature - exports public APIs.
library;

// Data - Datasources (for DI visibility)
export 'data/datasources/supabase_auth_datasource.dart';
export 'data/datasources/user_local_datasource.dart';
export 'data/datasources/user_remote_datasource.dart';

// Data - Models
export 'data/models/user_model.dart';

// Data - Repositories
export 'data/repositories/auth_repository_implementation.dart';
export 'data/repositories/user_repository_implementation.dart';

// Domain - Entities
export 'domain/entities/user_entity.dart';

// Domain - Repositories
export 'domain/repositories/auth_repository.dart';
export 'domain/repositories/user_repository.dart';

// Domain - Use Cases
export 'domain/usecases/get_current_user_use_case.dart';
export 'domain/usecases/sign_in_with_email_params.dart';
export 'domain/usecases/sign_in_with_email_use_case.dart';
export 'domain/usecases/sign_out_use_case.dart';
export 'domain/usecases/sign_up_with_email_params.dart';
export 'domain/usecases/sign_up_with_email_use_case.dart';
export 'domain/usecases/verify_magic_link_params.dart';
export 'domain/usecases/verify_magic_link_use_case.dart';

// Presentation - BLoC
export 'presentation/bloc/authentication_bloc.dart';
export 'presentation/bloc/authentication_event.dart';
export 'presentation/bloc/authentication_state.dart';
```

---

### Task 9: Delete `.gitkeep` from BLoC Directory

```bash
rm lib/features/auth/presentation/bloc/.gitkeep
```

---

### Task 10: Write Unit Tests for `GetCurrentUserUseCase`

**File:** `test/features/auth/domain/usecases/get_current_user_use_case_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/get_current_user_use_case.dart';

class MockAuthRepository extends Mock
    implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late GetCurrentUserUseCase useCase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = GetCurrentUserUseCase(mockAuthRepository);
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

  group('GetCurrentUserUseCase', () {
    test(
      'returns Right(UserEntity) when user is '
      'authenticated',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(testUser));

        final result =
            await useCase(const NoParams());

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (user) =>
              expect(user.id, equals('user-123')),
        );
        verify(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).called(1);
      },
    );

    test(
      'returns Left(Failure) when no user '
      'authenticated',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => const Left(
            UserNotFoundFailure(
              technicalDetails: 'No session',
            ),
          ),
        );

        final result =
            await useCase(const NoParams());

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            isA<UserNotFoundFailure>(),
          ),
          (_) => fail('Expected Left'),
        );
      },
    );
  });
}
```

---

### Task 11: Write Unit Tests for `SignOutUseCase`

**File:** `test/features/auth/domain/usecases/sign_out_use_case_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_out_use_case.dart';

class MockAuthRepository extends Mock
    implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late SignOutUseCase useCase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = SignOutUseCase(mockAuthRepository);
  });

  group('SignOutUseCase', () {
    test('returns Right(unit) on successful sign out',
        () async {
      when(() => mockAuthRepository.signOut())
          .thenAnswer(
        (_) async => const Right(unit),
      );

      final result =
          await useCase(const NoParams());

      expect(result.isRight(), isTrue);
      verify(() => mockAuthRepository.signOut())
          .called(1);
    });

    test(
      'returns Left(SignOutFailure) when sign out '
      'fails',
      () async {
        when(() => mockAuthRepository.signOut())
            .thenAnswer(
          (_) async => const Left(
            SignOutFailure(
              technicalDetails: 'Sign out failed',
            ),
          ),
        );

        final result =
            await useCase(const NoParams());

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            isA<SignOutFailure>(),
          ),
          (_) => fail('Expected Left'),
        );
      },
    );
  });
}
```

---

### Task 12: Write Unit Tests for `AuthenticationBloc`

**File:** `test/features/auth/presentation/bloc/authentication_bloc_test.dart`

> **⚠️ CRITICAL:** Uses `bloc_test` package. Must mock use cases AND repository (for stream). Must register `NoParams` as fallback value.

```dart
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_event.dart';
import 'package:tkd_brackets/features/auth/presentation/bloc/authentication_state.dart';

class MockGetCurrentUserUseCase extends Mock
    implements GetCurrentUserUseCase {}

class MockSignOutUseCase extends Mock
    implements SignOutUseCase {}

class MockAuthRepository extends Mock
    implements AuthRepository {}

void main() {
  late MockGetCurrentUserUseCase
      mockGetCurrentUserUseCase;
  late MockSignOutUseCase mockSignOutUseCase;
  late MockAuthRepository mockAuthRepository;
  late StreamController<Either<Failure, UserEntity?>>
      authStateController;

  final testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    organizationId: 'org-123',
    role: UserRole.owner,
    isActive: true,
    createdAt: DateTime(2026),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockGetCurrentUserUseCase =
        MockGetCurrentUserUseCase();
    mockSignOutUseCase = MockSignOutUseCase();
    mockAuthRepository = MockAuthRepository();
    authStateController = StreamController<
        Either<Failure, UserEntity?>>.broadcast();

    when(() => mockAuthRepository.authStateChanges)
        .thenAnswer(
      (_) => authStateController.stream,
    );
  });

  tearDown(() {
    authStateController.close();
  });

  AuthenticationBloc buildBloc() {
    return AuthenticationBloc(
      mockGetCurrentUserUseCase,
      mockSignOutUseCase,
      mockAuthRepository,
    );
  }

  group('AuthenticationBloc', () {
    test('initial state is AuthenticationInitial', () {
      final bloc = buildBloc();
      expect(
        bloc.state,
        const AuthenticationState.initial(),
      );
      bloc.close();
    });

    group('AuthenticationCheckRequested', () {
      blocTest<AuthenticationBloc,
          AuthenticationState>(
        'emits [checkInProgress, authenticated] '
        'when user exists',
        build: buildBloc,
        setUp: () {
          when(() => mockGetCurrentUserUseCase(any()))
              .thenAnswer(
            (_) async => Right(testUser),
          );
        },
        act: (bloc) => bloc.add(
          const AuthenticationEvent.checkRequested(),
        ),
        expect: () => [
          const AuthenticationState.checkInProgress(),
          AuthenticationState.authenticated(testUser),
        ],
      );

      blocTest<AuthenticationBloc,
          AuthenticationState>(
        'emits [checkInProgress, unauthenticated] '
        'when no user',
        build: buildBloc,
        setUp: () {
          when(() => mockGetCurrentUserUseCase(any()))
              .thenAnswer(
            (_) async => const Left(
              UserNotFoundFailure(
                technicalDetails: 'No session',
              ),
            ),
          );
        },
        act: (bloc) => bloc.add(
          const AuthenticationEvent.checkRequested(),
        ),
        expect: () => [
          const AuthenticationState.checkInProgress(),
          const AuthenticationState.unauthenticated(),
        ],
      );
    });

    group('AuthenticationUserChanged', () {
      blocTest<AuthenticationBloc,
          AuthenticationState>(
        'emits [authenticated] when user is not null',
        build: buildBloc,
        act: (bloc) => bloc.add(
          AuthenticationEvent.userChanged(testUser),
        ),
        expect: () => [
          AuthenticationState.authenticated(testUser),
        ],
      );

      blocTest<AuthenticationBloc,
          AuthenticationState>(
        'emits [unauthenticated] when user is null',
        build: buildBloc,
        act: (bloc) => bloc.add(
          const AuthenticationEvent.userChanged(null),
        ),
        expect: () => [
          const AuthenticationState.unauthenticated(),
        ],
      );
    });

    group('AuthenticationSignOutRequested', () {
      blocTest<AuthenticationBloc,
          AuthenticationState>(
        'emits [signOutInProgress, unauthenticated] '
        'on success',
        build: buildBloc,
        setUp: () {
          when(() => mockSignOutUseCase(any()))
              .thenAnswer(
            (_) async => const Right(unit),
          );
        },
        act: (bloc) => bloc.add(
          const AuthenticationEvent
              .signOutRequested(),
        ),
        expect: () => [
          const AuthenticationState
              .signOutInProgress(),
          const AuthenticationState.unauthenticated(),
        ],
      );

      blocTest<AuthenticationBloc,
          AuthenticationState>(
        'emits [signOutInProgress, failure] '
        'on error',
        build: buildBloc,
        setUp: () {
          when(() => mockSignOutUseCase(any()))
              .thenAnswer(
            (_) async => const Left(
              SignOutFailure(
                technicalDetails: 'Failed',
              ),
            ),
          );
        },
        act: (bloc) => bloc.add(
          const AuthenticationEvent
              .signOutRequested(),
        ),
        expect: () => [
          const AuthenticationState
              .signOutInProgress(),
          isA<AuthenticationFailure>(),
        ],
      );
    });

    group('auth state stream subscription', () {
      blocTest<AuthenticationBloc,
          AuthenticationState>(
        'reacts to auth state changes from stream',
        build: buildBloc,
        act: (bloc) async {
          authStateController.add(
            Right<Failure, UserEntity?>(testUser),
          );
          await Future<void>.delayed(
            const Duration(milliseconds: 100),
          );
        },
        expect: () => [
          AuthenticationState.authenticated(testUser),
        ],
      );

      blocTest<AuthenticationBloc,
          AuthenticationState>(
        'handles null user from stream '
        '(signed out)',
        build: buildBloc,
        act: (bloc) async {
          authStateController.add(
            const Right<Failure, UserEntity?>(null),
          );
          await Future<void>.delayed(
            const Duration(milliseconds: 100),
          );
        },
        expect: () => [
          const AuthenticationState.unauthenticated(),
        ],
      );

      blocTest<AuthenticationBloc,
          AuthenticationState>(
        'ignores stream errors silently',
        build: buildBloc,
        act: (bloc) async {
          authStateController.add(
            const Left<Failure, UserEntity?>(
              ServerConnectionFailure(
                technicalDetails: 'Stream error',
              ),
            ),
          );
          await Future<void>.delayed(
            const Duration(milliseconds: 100),
          );
        },
        expect: () => <AuthenticationState>[],
      );
    });

    test(
      'subscribes to authStateChanges during '
      'construction',
      () {
        buildBloc();
        verify(
          () => mockAuthRepository.authStateChanges,
        ).called(1);
      },
    );

    test('cancels stream subscription on close',
        () async {
      final bloc = buildBloc();
      await bloc.close();

      // After close, adding to stream should
      // not affect bloc
      authStateController.add(
        Right<Failure, UserEntity?>(testUser),
      );

      // No error thrown = subscription cancelled
      expect(bloc.isClosed, isTrue);
    });
  });
}
```

---

### Task 13: Integration Verification

```bash
# From tkd_brackets/ directory:

# Delete the .gitkeep placeholder
rm lib/features/auth/presentation/bloc/.gitkeep

# Generate freezed/injectable code
dart run build_runner build --delete-conflicting-outputs

# Run static analysis
flutter analyze

# Run auth tests
flutter test test/features/auth/

# Optionally build to verify no runtime issues
flutter build web --release -t lib/main_development.dart
```

All must pass with zero errors.

---

## Dev Notes

### Epic AC Deviation: Missing Events

The epics (Story 2.5 AC, line 1012) specify events `AuthCheckRequested`, `AuthSignUpRequested`, `AuthSignInRequested`, `AuthLogoutRequested`. This story **intentionally omits** `AuthSignUpRequested` and `AuthSignInRequested` because:

1. **Separation of concerns**: The `AuthenticationBloc` manages *global auth state observation*, NOT auth *flows*. Sign-up and sign-in are per-screen flows handled by their own BLoCs (e.g., future `SignInBloc`, `SignUpBloc`) in the presentation layer.
2. **Reactive architecture**: The `AuthenticationBloc` reacts to the *outcome* of those flows via the `authStateChanges` stream. When a sign-in BLoC successfully authenticates, the auth stream emits, and `AuthenticationBloc` transitions to `authenticated`.
3. **Single Responsibility**: Combining flow orchestration and state observation in one BLoC would violate SRP and create a god-object.

This means sign-up/sign-in UI pages will dispatch to their own BLoCs, NOT to `AuthenticationBloc`.

### AuthenticationBloc Lifecycle

1. **App Startup** → `App.initState()` dispatches `AuthenticationCheckRequested`
2. **Widget Tree** → `BlocProvider.value` provides the singleton to the widget tree
3. **Session Recovery** → `GetCurrentUserUseCase` checks Supabase session → local cache → remote
4. **Ongoing Monitoring** → `authStateChanges` stream subscription reacts to external auth changes
5. **Router Reactivity** → `GoRouterRefreshStream` triggers redirect re-evaluation on each state change
6. **Sign Out** → `SignOutUseCase` clears Supabase session, stream emits null, state becomes `unauthenticated`

### State Machine

```
┌──────────┐  checkRequested  ┌────────────────┐
│ initial  │ ──────────────→ │ checkInProgress │
└──────────┘                  └───────┬────────┘
                                      │
                          ┌───────────┴───────────┐
                          ▼                       ▼
                  ┌──────────────┐     ┌─────────────────┐
                  │authenticated │     │ unauthenticated  │
                  └──────┬───────┘     └────────┬────────┘
                         │                      │
              signOut    │                      │ (external login)
              Requested  │                      │
                         ▼                      │
                  ┌─────────────────┐           │
                  │signOutInProgress│           │
                  └───────┬────────┘           │
                          │                     │
                ┌─────────┴─────────┐          │
                ▼                   ▼          │
        ┌──────────────┐    ┌──────────┐       │
        │unauthenticated│   │ failure  │       │
        └──────────────┘    └──────────┘       │
```

### Why BLoC Accesses AuthRepository Directly for Stream

The `AuthenticationBloc` imports `AuthRepository` directly for the `authStateChanges` stream. This is an intentional deviation from the "BLoC calls use cases only" rule because:
1. Creating a use case that just exposes a `Stream` adds boilerplate without value
2. The stream subscription is an infrastructure concern (lifecycle management), not business logic
3. This is a common, accepted pattern in Flutter BLoC architecture

### Router Redirect Guard Behavior

| Auth State          | Public Route (`/`, `/demo`) | Protected Route (`/dashboard`, etc.) |
| ------------------- | --------------------------- | ------------------------------------ |
| `initial`           | Allow (no redirect)         | Allow (pending check)                |
| `checkInProgress`   | Allow (no redirect)         | Allow (pending check)                |
| `authenticated`     | Redirect → `/dashboard`     | Allow                                |
| `unauthenticated`   | Allow                       | Redirect → `/`                       |
| `signOutInProgress` | Allow                       | Redirect → `/`                       |
| `failure`           | Allow                       | Redirect → `/`                       |

### Files Created vs Modified

| Type         | File                                                                     |
| ------------ | ------------------------------------------------------------------------ |
| **Created**  | `lib/features/auth/domain/usecases/get_current_user_use_case.dart`       |
| **Created**  | `lib/features/auth/domain/usecases/sign_out_use_case.dart`               |
| **Created**  | `lib/features/auth/presentation/bloc/authentication_event.dart`          |
| **Created**  | `lib/features/auth/presentation/bloc/authentication_state.dart`          |
| **Created**  | `lib/features/auth/presentation/bloc/authentication_bloc.dart`           |
| **Created**  | `test/features/auth/domain/usecases/get_current_user_use_case_test.dart` |
| **Created**  | `test/features/auth/domain/usecases/sign_out_use_case_test.dart`         |
| **Created**  | `test/features/auth/presentation/bloc/authentication_bloc_test.dart`     |
| **Modified** | `lib/app/app.dart` (add `BlocProvider.value`, dispatch in `initState`)   |
| **Modified** | `lib/core/router/app_router.dart` (auth redirect + `refreshListenable`)  |
| **Modified** | `lib/features/auth/auth.dart` (add exports)                              |
| **Deleted**  | `lib/features/auth/presentation/bloc/.gitkeep`                           |

### ⚠️ CRITICAL Implementation Warnings

1. **BLoC is `@lazySingleton`** — NOT `@injectable` (factory). Auth state is global.
2. **Stream subscription** — MUST cancel in `close()` to prevent memory leaks.
3. **Use `BlocProvider.value`** — NOT `BlocProvider(create:)`. Since BLoC is a `@lazySingleton`, `BlocProvider(create:)` would call `close()` on widget disposal, permanently closing the singleton. `BlocProvider.value` delegates lifecycle to `getIt`.
4. **Dispatch `checkRequested` in `initState`** — NOT in `build()`. Dispatching in `build()` would re-dispatch on every widget rebuild.
5. **Router accesses BLoC via `getIt`** — NOT `context.read<AuthenticationBloc>()` because `AppRouter` is created before the widget tree.
6. **Router MUST have `refreshListenable`** — Without `GoRouterRefreshStream` bridging the BLoC stream to `GoRouter`, auth state changes would NOT trigger redirect re-evaluation. Users would stay on old pages after login/logout.
7. **`AuthenticationUserChanged` is internal** — Only dispatched by the stream subscription. UI MUST NEVER dispatch this event directly.
8. **Check failure → unauthenticated** — When `GetCurrentUserUseCase` returns `Left(Failure)`, emit `unauthenticated` (NOT `failure`). Failed session check means "not logged in", not "error state".
9. **Stream errors are silently ignored** — The auth state stream can emit `Left(Failure)` (e.g., network error while fetching user). We ignore these to avoid disrupting the current auth state.
10. **Build runner MUST run** — Freezed events and states require code generation. Run `dart run build_runner build --delete-conflicting-outputs` before testing.
11. **No sign-up/sign-in events in AuthenticationBloc** — These are handled by separate per-screen BLoCs. See "Epic AC Deviation" in Dev Notes.

### Common Mistakes to Avoid

| ❌ Don't                                      | ✅ Do                                               |
| -------------------------------------------- | -------------------------------------------------- |
| Name it `AuthBloc`                           | Name it `AuthenticationBloc` (full words)          |
| Use `@injectable` (factory)                  | Use `@lazySingleton` (global state)                |
| Call repository from BLoC                    | Call use cases from BLoC                           |
| Forget `close()` override                    | Cancel stream subscription in `close()`            |
| Use `BlocProvider(create:)` for singleton    | Use `BlocProvider.value` (lifecycle via `getIt`)   |
| Dispatch `checkRequested` in `build()`       | Dispatch in `initState()` (runs once)              |
| Omit `refreshListenable` from GoRouter       | Use `GoRouterRefreshStream` for reactive redirects |
| Emit `failure` on check fail                 | Emit `unauthenticated` on check fail               |
| Redirect during `initial`/`checkInProgress`  | Wait for auth check to complete                    |
| Dispatch `AuthenticationUserChanged` from UI | This is internal-only (stream subscription)        |
| Forget `build_runner`                        | Run code gen for freezed events/states             |
| Add `AuthSignUpRequested` event              | Sign-up/sign-in are separate BLoCs (see Dev Notes) |

---

## Checklist

### Pre-Implementation
- [ ] Verify Stories 2.1-2.4 are complete
- [ ] Review existing `AuthRepository` interface
- [ ] Check `auth_failures.dart` for available failure classes
- [ ] Confirm `bloc`, `flutter_bloc`, `bloc_test` are in pubspec.yaml
- [ ] Review `app.dart` and `app_router.dart` for modification points

### Implementation
- [ ] Task 1: Create `GetCurrentUserUseCase`
- [ ] Task 2: Create `SignOutUseCase`
- [ ] Task 3: Create `AuthenticationEvent` with freezed
- [ ] Task 4: Create `AuthenticationState` with freezed
- [ ] Task 5: Create `AuthenticationBloc`
- [ ] Task 6: Update `App` widget with `BlocProvider.value` + `initState` dispatch
- [ ] Task 7: Update router auth redirect guard + `GoRouterRefreshStream` + `refreshListenable`
- [ ] Task 8: Update auth barrel file with exports
- [ ] Task 9: Delete `.gitkeep` from BLoC directory
- [ ] Task 10: Write `GetCurrentUserUseCase` tests
- [ ] Task 11: Write `SignOutUseCase` tests
- [ ] Task 12: Write `AuthenticationBloc` tests (incl. constructor subscription verification)
- [ ] Task 13: Run build_runner, analyze, and tests

### Post-Implementation
- [ ] `flutter analyze` - zero errors in auth feature
- [ ] `flutter test test/features/auth/` - all pass
- [ ] `flutter build web --release -t lib/main_development.dart` - succeeds
- [ ] Update story status to `done` (after code review)

> **📝 NOTE:** If a `test/features/auth/structure_test.dart` exists that validates feature file structure, update it to include the new BLoC files (`authentication_bloc.dart`, `authentication_event.dart`, `authentication_state.dart`) and new use cases (`get_current_user_use_case.dart`, `sign_out_use_case.dart`).

---

## Architecture References

| Document          | Relevant Sections                                                                  |
| ----------------- | ---------------------------------------------------------------------------------- |
| `architecture.md` | BLoC Patterns (770-807), Naming (932-983), Boundaries (1193-1246)                  |
| `epics.md`        | Story 2.5 (1002-1017), Epic 2 Overview (915-1119)                                  |
| Story 2.4         | `AuthRepository` full interface, `getCurrentAuthenticatedUser`, `authStateChanges` |
| Story 2.3         | `SupabaseAuthDatasource` patterns                                                  |

---

## File Manifest

### New Files to Create

| File                                                                     | Purpose                   |
| ------------------------------------------------------------------------ | ------------------------- |
| `lib/features/auth/domain/usecases/get_current_user_use_case.dart`       | Get current user use case |
| `lib/features/auth/domain/usecases/sign_out_use_case.dart`               | Sign out use case         |
| `lib/features/auth/presentation/bloc/authentication_event.dart`          | BLoC events (freezed)     |
| `lib/features/auth/presentation/bloc/authentication_state.dart`          | BLoC states (freezed)     |
| `lib/features/auth/presentation/bloc/authentication_bloc.dart`           | Authentication BLoC       |
| `test/features/auth/domain/usecases/get_current_user_use_case_test.dart` | Use case tests            |
| `test/features/auth/domain/usecases/sign_out_use_case_test.dart`         | Use case tests            |
| `test/features/auth/presentation/bloc/authentication_bloc_test.dart`     | BLoC tests                |

### Files to Modify

| File                              | Modification                           |
| --------------------------------- | -------------------------------------- |
| `lib/app/app.dart`                | Add `BlocProvider<AuthenticationBloc>` |
| `lib/core/router/app_router.dart` | Implement auth redirect guard          |
| `lib/features/auth/auth.dart`     | Add exports for new files              |

### Files to Delete

| File                                           | Reason                 |
| ---------------------------------------------- | ---------------------- |
| `lib/features/auth/presentation/bloc/.gitkeep` | Replaced by BLoC files |

---

## Agent Record

| Field        | Value                                 |
| ------------ | ------------------------------------- |
| Created By   | create-story workflow                 |
| Created At   | 2026-02-09                            |
| Source Epic  | Epic 2: Authentication & Organization |
| Story Points | 5                                     |

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List

### Change Log
