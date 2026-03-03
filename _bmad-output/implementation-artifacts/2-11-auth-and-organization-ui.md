# Story 2.11: Auth & Organization UI

Status: ready-for-dev

## Story

As a user,
I want a UI to sign up, log in with a magic link, and manage my organization,
so that I can authenticate, configure my dojang, and invite team members.

## Acceptance Criteria

> **AC1:** An `AuthPage` exists at route `/auth` that provides:
>   - Email input field with validation (non-empty, valid email format)
>   - "Sign Up" (primary) and "Sign In" (secondary) buttons
>   - Loading state while magic link is sent
>   - Success state showing "Check your email for the magic link" message
>   - Error state showing user-friendly failure message  
>   - Material Design 3 theming with Navy/Gold brand colors
>
> **AC2:** A magic link verification handler is implemented:
>   - Listens for Supabase deep link callback or handles OTP token from URL
>   - Calls `VerifyMagicLinkUseCase` with email+token
>   - Shows loading spinner during verification
>   - On success: navigates to `/dashboard` (or `/organization/setup` if no org)
>   - On failure: shows error and returns to `AuthPage`
>
> **AC3:** An `OrganizationSetupPage` exists at route `/organization/setup`:
>   - Organization name input field (required, min 2 chars)
>   - Auto-generated slug preview using `CreateOrganizationUseCase.generateSlug()` static method
>   - "Create Organization" submit button
>   - Calls `CreateOrganizationUseCase` with `CreateOrganizationParams(name: name, userId: currentUser.id)`
>   - On success: navigates to `/dashboard` (demo migration runs internally — DO NOT call separately)
>   - Error handling for validation failures
>
> **AC4:** An `OrganizationDashboardPage` exists at route `/organization`:
>   - Shows organization name, subscription tier badge (Free/Pro/Enterprise)
>   - "Members" section listing current organization members with roles
>   - "Pending Invitations" section listing sent invitations  
>   - "Invite Member" button opening invite dialog
>
> **AC5:** An `InviteMemberDialog` modal allows:
>   - Email input field with validation
>   - Role selection dropdown (Admin, Scorer, Viewer — NOT Owner)
>   - "Send Invitation" button dispatches event that calls `SendInvitationUseCase` with `SendInvitationParams(email: email, organizationId: currentUser.organizationId, role: selectedRole, invitedByUserId: currentUser.id)`
>   - Loading and success/error states
>
> **AC6:** A `UserSettingsPage` exists at route `/settings` (replaces placeholder):
>   - Display current user email and display name
>   - Organization info section (name, role, subscription tier)
>   - "Sign Out" button dispatching `AuthenticationSignOutRequested` event
>   - Member management (if Owner/Admin): role change and member removal
>
> **AC7:** `AuthBloc` state dictates navigation via `_redirectGuard`:
>   - `AuthenticationUnauthenticated` → redirect to `/auth` for protected routes
>   - `AuthenticationAuthenticated` → redirect to `/dashboard` from `/auth`
>   - `AuthenticationAuthenticated` with empty `organizationId` → redirect to `/organization/setup`
>   - User on `/organization/setup` who already has an org → redirect to `/dashboard`
>
> **AC8:** Feature-scoped BLoCs are created:
>   - `SignInBloc` — handles sign-up/sign-in form state and magic link flow
>   - `OrganizationBloc` — handles org creation, member list, invitation management  
>   - Both follow project event/state naming conventions (freezed)
>
> **AC9:** All routes are registered with `go_router_builder` type-safe route definitions:
>   - `AuthRoute` at `/auth` (public, top-level route — NO shell)
>   - `MagicLinkCallbackRoute` at `/auth/callback` (public, top-level route — NO shell)
>   - `OrganizationSetupRoute` at `/organization/setup` (authenticated, top-level route — NO shell, user has no org yet)
>   - `OrganizationRoute` at `/organization` (authenticated, inside shell routes)
>
> **AC10:** All new pages render correctly in Chrome without overflow or layout issues
>
> **AC11:** `HomePage` "Sign In" button navigates to `/auth` (replace existing TODO stub)
>
> **AC12:** All new exports are added to `auth.dart` barrel file in correct sections and alphabetical order
>
> **AC13:** `flutter analyze` passes with zero new errors
>
> **AC14:** `build_runner` generates code successfully for all new freezed/go_router_builder classes
>
> **AC15:** Widget tests verify:
>   - AuthPage renders email input and both sign-up/sign-in buttons
>   - AuthPage shows loading indicator during magic link send
>   - AuthPage shows success message after magic link sent
>   - OrganizationSetupPage renders name input and create button
>   - UserSettingsPage renders user info and sign-out button
>   - Navigation guards redirect unauthenticated users to `/auth`

## Tasks / Subtasks

- [ ] Task 1: Create `SignInBloc` (AC: #8)
  - [ ] 1.1: Create `sign_in_event.dart` with freezed events: `SignUpRequested(email)`, `SignInRequested(email)`, `MagicLinkVerificationRequested(email, token)`, `FormReset`
  - [ ] 1.2: Create `sign_in_state.dart` with freezed states: `SignInInitial`, `SignInLoadInProgress`, `SignInMagicLinkSent(email)`, `SignInVerificationInProgress`, `SignInSuccess(user)`, `SignInFailure(failure)`  
  - [ ] 1.3: Create `sign_in_bloc.dart` injecting `SignUpWithEmailUseCase`, `SignInWithEmailUseCase`, `VerifyMagicLinkUseCase`
- [ ] Task 2: Create `OrganizationBloc` (AC: #8)
  - [ ] 2.1: Create `organization_management_event.dart` with events: `OrganizationCreationRequested(name, userId)`, `OrganizationLoadRequested(organizationId)`, `InvitationSendRequested(email, role, organizationId, invitedByUserId)`, `MemberRoleUpdateRequested(targetUserId, newRole, requestingUserId)`, `MemberRemovalRequested(targetUserId, requestingUserId)`
  - [ ] 2.2: Create `organization_management_state.dart` with states: `OrganizationManagementInitial`, `OrganizationManagementLoadInProgress`, `OrganizationManagementLoadSuccess(org, members, invitations)`, `OrganizationManagementCreationInProgress`, `OrganizationManagementCreationSuccess(org)`, `OrganizationManagementOperationSuccess(message)`, `OrganizationManagementFailure(failure)`
  - [ ] 2.3: Create `organization_management_bloc.dart` injecting `CreateOrganizationUseCase`, `OrganizationRepository`, `UserRepository`, `InvitationRepository`, `SendInvitationUseCase`, `UpdateUserRoleUseCase`, `RemoveOrganizationMemberUseCase` — **DO NOT inject MigrateDemoDataUseCase** (already called internally by CreateOrganizationUseCase)
- [ ] Task 3: Create `AuthPage` (AC: #1)
  - [ ] 3.1: Create `lib/features/auth/presentation/pages/auth_page.dart`
  - [ ] 3.2: Build email input with `TextFormField` + email validation
  - [ ] 3.3: Build "Sign Up" (`FilledButton`) and "Sign In" (`OutlinedButton`) buttons
  - [ ] 3.4: Use `BlocBuilder<SignInBloc, SignInState>` for reactive state rendering
  - [ ] 3.5: Show success card with "Check your email" message on `SignInMagicLinkSent`
  - [ ] 3.6: Apply Material Design 3 theming (centered card layout, max width 400px like HomePage)
- [ ] Task 4: Create Magic Link Verification Handler (AC: #2)
  - [ ] 4.1: Create `lib/features/auth/presentation/pages/magic_link_callback_page.dart`
  - [ ] 4.2: Extract `email` and `token` from URL query parameters — **Flutter Web receives deep link via `Uri.base` or GoRouter's `state.uri.queryParameters`**
  - [ ] 4.3: Dispatch `MagicLinkVerificationRequested` to `SignInBloc`
  - [ ] 4.4: On `SignInSuccess(user)`: check `user.organizationId` — if empty, navigate to `/organization/setup`; otherwise navigate to `/dashboard`
  - [ ] 4.5: Register route `MagicLinkCallbackRoute` at `/auth/callback` as PUBLIC top-level route
- [ ] Task 5: Create `OrganizationSetupPage` (AC: #3)
  - [ ] 5.1: Create `lib/features/auth/presentation/pages/organization_setup_page.dart`
  - [ ] 5.2: Build organization name input with slug preview — use `CreateOrganizationUseCase.generateSlug(name)` static method for preview
  - [ ] 5.3: "Create Organization" button dispatches `OrganizationCreationRequested(name: name, userId: currentUser.id)` — get `currentUser` from `context.read<AuthenticationBloc>().state` cast to `AuthenticationAuthenticated`
  - [ ] 5.4: On `OrganizationManagementCreationSuccess`, navigate to `/dashboard`
- [ ] Task 6: Create `OrganizationDashboardPage` (AC: #4)
  - [ ] 6.1: Create `lib/features/auth/presentation/pages/organization_dashboard_page.dart`
  - [ ] 6.2: Build org info header with name and subscription tier badge
  - [ ] 6.3: Build members list with role chips using `ListView`
  - [ ] 6.4: Build pending invitations list with status
  - [ ] 6.5: Add "Invite Member" FAB or button
- [ ] Task 7: Create `InviteMemberDialog` (AC: #5)
  - [ ] 7.1: Create `lib/features/auth/presentation/widgets/invite_member_dialog.dart`
  - [ ] 7.2: Email input + Role dropdown (Admin, Scorer, Viewer)
  - [ ] 7.3: Submit dispatches `InvitationSendRequested` to `OrganizationBloc`
- [ ] Task 8: Update `SettingsPage` (AC: #6)
  - [ ] 8.1: Replace placeholder with real user info from `AuthenticationBloc` state
  - [ ] 8.2: Show current user's email, display name, role, org name
  - [ ] 8.3: Add Sign Out button dispatching `AuthenticationSignOutRequested`
  - [ ] 8.4: Show member management section for Owner/Admin (role change, remove)
- [ ] Task 9: Update Router & Navigation (AC: #7, #9, #11)
  - [ ] 9.1: Add `AuthRoute` at `/auth` (public, top-level) in `routes.dart`
  - [ ] 9.2: Add `MagicLinkCallbackRoute` at `/auth/callback` (public, top-level) in `routes.dart`
  - [ ] 9.3: Add `OrganizationSetupRoute` at `/organization/setup` (authenticated, top-level — NOT inside shell) in `routes.dart`
  - [ ] 9.4: Add `OrganizationRoute` at `/organization` inside shell routes in `app_router.dart`
  - [ ] 9.5: Add `$authRoute`, `$magicLinkCallbackRoute`, `$organizationSetupRoute` to top-level routes array in `app_router.dart` (alongside `$homeRoute`, `$demoRoute`)
  - [ ] 9.6: Add `$organizationRoute` inside `createAppShellRoute` routes array
  - [ ] 9.7: Update `_redirectGuard` — add `/auth`, `/auth/callback` to `publicRoutes`; add `/organization/setup` as a special authenticated-but-no-org route
  - [ ] 9.8: Update `_redirectGuard` — when `AuthenticationAuthenticated(user)` and `user.organizationId.isEmpty`, redirect to `/organization/setup` (except if already on `/organization/setup`)
  - [ ] 9.9: Update `HomePage` Sign In button: replace TODO with `const AuthRoute().go(context)`
  - [ ] 9.10: Add `NavItem` for Organization in `navigation_items.dart` — path: `/organization`, label: `Organization`, icon: `Icons.business_outlined`/`Icons.business`
- [ ] Task 10: Update barrel file (AC: #12)
  - [ ] 10.1: Add all new presentation exports to `auth.dart` in alphabetical order
- [ ] Task 11: Write widget tests (AC: #15)
  - [ ] 11.1: `auth_page_test.dart` — renders email input, buttons, loading, success states
  - [ ] 11.2: `organization_setup_page_test.dart` — renders form, submits correctly
  - [ ] 11.3: `settings_page_test.dart` — renders user info, sign-out button works
  - [ ] 11.4: `sign_in_bloc_test.dart` — event→state transitions for sign-up/sign-in flows
  - [ ] 11.5: `organization_management_bloc_test.dart` — event→state for org creation, invites
- [ ] Task 12: Run `build_runner` (AC: #14)
- [ ] Task 13: Run `flutter analyze` (AC: #13)
- [ ] Task 14: Verify all pages render in Chrome (AC: #10)

## Dev Notes

### Critical Implementation Details

**1. Existing Domain Layer (Stories 2.1–2.10) — DO NOT Recreate:**

All domain logic is already implemented. The UI must ONLY call existing use cases:

| Use Case                          | Location                                                   | Purpose                                                      |
| --------------------------------- | ---------------------------------------------------------- | ------------------------------------------------------------ |
| `SignUpWithEmailUseCase`          | `domain/usecases/sign_up_with_email_use_case.dart`         | Send signup magic link                                       |
| `SignInWithEmailUseCase`          | `domain/usecases/sign_in_with_email_use_case.dart`         | Send signin magic link                                       |
| `VerifyMagicLinkUseCase`          | `domain/usecases/verify_magic_link_use_case.dart`          | Verify OTP token from magic link                             |
| `SignOutUseCase`                  | `domain/usecases/sign_out_use_case.dart`                   | Sign out current user                                        |
| `GetCurrentUserUseCase`           | `domain/usecases/get_current_user_use_case.dart`           | Fetch current authenticated user                             |
| `CreateOrganizationUseCase`       | `domain/usecases/create_organization_use_case.dart`        | Create org + triggers demo migration                         |
| `SendInvitationUseCase`           | `domain/usecases/send_invitation_use_case.dart`            | Send team invitation                                         |
| `AcceptInvitationUseCase`         | `domain/usecases/accept_invitation_use_case.dart`          | Accept team invitation                                       |
| `UpdateUserRoleUseCase`           | `domain/usecases/update_user_role_use_case.dart`           | Change member role                                           |
| `RemoveOrganizationMemberUseCase` | `domain/usecases/remove_organization_member_use_case.dart` | Remove member                                                |
| `MigrateDemoDataUseCase`          | `domain/usecases/migrate_demo_data_use_case.dart`          | Migrate demo data (auto-called by CreateOrganizationUseCase) |

**⚠️ CRITICAL: `CreateOrganizationUseCase` already calls `MigrateDemoDataUseCase` internally (Story 2.10). Do NOT call migration again from the UI.**

**2. Existing `AuthenticationBloc` — DO NOT Modify (unless adding events):**

The global `AuthenticationBloc` (singleton) already:
- Listens to `authStateChanges` stream from `AuthRepository`
- Handles `AuthenticationCheckRequested`, `AuthenticationUserChanged`, `AuthenticationSignOutRequested`
- Manages states: `initial → checkInProgress → authenticated(user) / unauthenticated / failure`

The UI should read state from this BLoC. New feature-scoped BLoCs (`SignInBloc`, `OrganizationBloc`) handle form interactions.

**3. Router Configuration — Existing Patterns to Follow:**

Current `app_router.dart` (line 57-83) shows:
- Public routes at top-level: `$homeRoute`, `$demoRoute`  
- Shell routes wrapped in `createAppShellRoute()`
- `_redirectGuard()` handles auth redirects (lines 91-138)

**New routes to add:**
```dart
// In app_router.dart routes: [] array:

// Public routes (no auth required) — top-level:
$authRoute,              // /auth
$magicLinkCallbackRoute, // /auth/callback

// Authenticated, no shell (before org exists) — top-level:
$organizationSetupRoute, // /organization/setup

// Shell routes (authenticated + org exists) — inside createAppShellRoute:
createAppShellRoute(
  shellNavigatorKey: _shellNavigatorKey,
  routes: [
    $dashboardRoute,
    $tournamentListRoute,
    $tournamentDetailsRoute,
    $tournamentDivisionsRoute,
    $participantListRoute,
    $csvImportRoute,
    $organizationRoute,   // ← ADD HERE
    $settingsRoute,
  ],
),
```

**Redirect guard update (EXACT code pattern for `_redirectGuard`):**
```dart
String? _redirectGuard(BuildContext context, GoRouterState state) {
  final location = state.matchedLocation;
  final authState = getIt<AuthenticationBloc>().state;

  const publicRoutes = ['/', '/demo', '/auth', '/auth/callback'];
  const demoAccessiblePrefixes = ['/tournaments'];

  final isPublicRoute = publicRoutes.contains(location);
  final isDemoAccessible = demoAccessiblePrefixes.any(
    (prefix) => location == prefix || location.startsWith('$prefix/'),
  );

  if (location == '/app' || location == '/app/') return '/dashboard';

  final isAuthenticated = authState is AuthenticationAuthenticated;

  // Authenticated user on public route → dashboard
  if (isAuthenticated && isPublicRoute) return '/dashboard';

  // Authenticated user without org → force org setup
  if (isAuthenticated) {
    final user = (authState as AuthenticationAuthenticated).user;
    final hasNoOrg = user.organizationId.isEmpty;
    final isOrgSetup = location == '/organization/setup';
    if (hasNoOrg && !isOrgSetup) return '/organization/setup';
    if (!hasNoOrg && isOrgSetup) return '/dashboard';
  }

  // Not authenticated, not public, not demo → redirect to /auth
  if (!isAuthenticated &&
      !isPublicRoute &&
      !isDemoAccessible &&
      authState is! AuthenticationCheckInProgress &&
      authState is! AuthenticationInitial) {
    return '/auth';  // ← Changed from '/' to '/auth'
  }

  return null;
}
```

**4. Theme & Layout Patterns — Follow Existing Code:**

- `AppTheme.light()` uses `ColorScheme.fromSeed(seedColor: Color(0xFF1E3A5F))` — Navy primary, Gold secondary
- `HomePage` uses `ConstrainedBox(maxWidth: 400)` centered layout — follow this for AuthPage
- `DashboardPage` and `SettingsPage` use `Center > Column > Icon + Text` pattern (placeholders)
- `AppShellScaffold` provides responsive navigation (NavigationRail on desktop, BottomNav on mobile)
- Use `Theme.of(context).colorScheme` and `Theme.of(context).textTheme` consistently
- Add `Semantics` labels on interactive elements (see `shell_routes.dart` lines 119-130 for pattern)

**5. File Placement — Clean Architecture Presentation Layer:**

```
lib/features/auth/presentation/
├── bloc/
│   ├── authentication_bloc.dart     ✅ EXISTS — DO NOT MODIFY
│   ├── authentication_event.dart    ✅ EXISTS
│   ├── authentication_state.dart    ✅ EXISTS
│   ├── sign_in_bloc.dart            ← NEW (feature-scoped)
│   ├── sign_in_event.dart           ← NEW
│   ├── sign_in_event.freezed.dart   ← GENERATED
│   ├── sign_in_state.dart           ← NEW
│   ├── sign_in_state.freezed.dart   ← GENERATED
│   ├── organization_management_bloc.dart  ← NEW (feature-scoped)
│   ├── organization_management_event.dart ← NEW
│   ├── organization_management_event.freezed.dart ← GENERATED
│   ├── organization_management_state.dart ← NEW
│   └── organization_management_state.freezed.dart ← GENERATED
├── pages/
│   ├── auth_page.dart                      ← NEW
│   ├── magic_link_callback_page.dart       ← NEW
│   ├── organization_setup_page.dart        ← NEW
│   └── organization_dashboard_page.dart    ← NEW
└── widgets/
    └── invite_member_dialog.dart           ← NEW
```

**6. Naming Conventions (MUST Follow):**

| Element | Pattern                      | Example                                            |
| ------- | ---------------------------- | -------------------------------------------------- |
| BLoC    | `{Feature}Bloc`              | `SignInBloc`, `OrganizationManagementBloc`         |
| Events  | `{Feature}{Action}Requested` | `SignUpRequested`, `OrganizationCreationRequested` |
| States  | `{Feature}{Status}`          | `SignInLoadInProgress`, `OrganizationLoadSuccess`  |
| Pages   | `{Feature}Page`              | `AuthPage`, `OrganizationSetupPage`                |
| Routes  | `{Feature}{Context}Route`    | `AuthRoute`, `OrganizationSetupRoute`              |

**7. BLoC Pattern for Pages:**

New BLoCs are **@injectable** (NOT `@lazySingleton`) since they are feature-scoped and disposed on navigation:

```dart
@injectable
class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc(
    this._signUpWithEmailUseCase,
    this._signInWithEmailUseCase,
    this._verifyMagicLinkUseCase,
  ) : super(const SignInState.initial()) {
    on<SignUpRequested>(_onSignUpRequested);
    on<SignInRequested>(_onSignInRequested);
    on<MagicLinkVerificationRequested>(_onVerificationRequested);
  }
  // ...
}
```

Pages provide BLoC with `BlocProvider`:
```dart
// AuthPage wrapping pattern:
class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SignInBloc>(),
      child: const _AuthPageContent(),
    );
  }
}

// OrganizationSetupPage wrapping pattern:
class OrganizationSetupPage extends StatelessWidget {
  const OrganizationSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrganizationManagementBloc>(),
      child: const _OrganizationSetupContent(),
    );
  }
}

// OrganizationDashboardPage needs BOTH blocs (for invites + member management):
class OrganizationDashboardPage extends StatelessWidget {
  const OrganizationDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrganizationManagementBloc>()
        ..add(OrganizationManagementEvent.loadRequested(
          organizationId: (context.read<AuthenticationBloc>().state
              as AuthenticationAuthenticated).user.organizationId,
        )),
      child: const _OrganizationDashboardContent(),
    );
  }
}
```

**OrganizationManagementBloc handler pattern (verbose example):**
```dart
@injectable
class OrganizationManagementBloc
    extends Bloc<OrganizationManagementEvent, OrganizationManagementState> {
  OrganizationManagementBloc(
    this._createOrganizationUseCase,
    this._organizationRepository,
    this._userRepository,
    this._invitationRepository,
    this._sendInvitationUseCase,
    this._updateUserRoleUseCase,
    this._removeOrganizationMemberUseCase,
  ) : super(const OrganizationManagementState.initial()) {
    on<OrganizationCreationRequested>(_onCreationRequested);
    on<OrganizationLoadRequested>(_onLoadRequested);
    on<InvitationSendRequested>(_onInvitationSendRequested);
    on<MemberRoleUpdateRequested>(_onMemberRoleUpdateRequested);
    on<MemberRemovalRequested>(_onMemberRemovalRequested);
  }

  Future<void> _onCreationRequested(
    OrganizationCreationRequested event,
    Emitter<OrganizationManagementState> emit,
  ) async {
    emit(const OrganizationManagementState.creationInProgress());
    final result = await _createOrganizationUseCase(
      CreateOrganizationParams(name: event.name, userId: event.userId),
    );
    result.fold(
      (failure) => emit(OrganizationManagementState.failure(failure)),
      (org) => emit(OrganizationManagementState.creationSuccess(org)),
    );
  }

  Future<void> _onLoadRequested(
    OrganizationLoadRequested event,
    Emitter<OrganizationManagementState> emit,
  ) async {
    emit(const OrganizationManagementState.loadInProgress());
    final orgResult = await _organizationRepository.getOrganizationById(event.organizationId);
    // Then fetch members via _userRepository.getUsersForOrganization(event.organizationId)
    // Then fetch invitations via _invitationRepository.getPendingInvitationsForOrganization(event.organizationId)
    // Combine into OrganizationManagementState.loadSuccess(org, members, invitations)
  }

  Future<void> _onInvitationSendRequested(
    InvitationSendRequested event,
    Emitter<OrganizationManagementState> emit,
  ) async {
    emit(const OrganizationManagementState.loadInProgress());
    final result = await _sendInvitationUseCase(
      SendInvitationParams(
        email: event.email,
        organizationId: event.organizationId,
        role: event.role,
        invitedByUserId: event.invitedByUserId,
      ),
    );
    result.fold(
      (failure) => emit(OrganizationManagementState.failure(failure)),
      (_) {
        emit(const OrganizationManagementState.operationSuccess('Invitation sent successfully'));
        // Re-fetch org data to update the list
        add(OrganizationLoadRequested(organizationId: event.organizationId));
      },
    );
  }
  // Similar patterns for _onMemberRoleUpdateRequested, _onMemberRemovalRequested
}
```

**8. Widget Test Pattern (Follow Project Conventions):**

```dart
// Use mocktail for mocking
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock BLoCs:
class MockSignInBloc extends MockBloc<SignInEvent, SignInState>
    implements SignInBloc {}
class MockAuthenticationBloc
    extends MockBloc<AuthenticationEvent, AuthenticationState>
    implements AuthenticationBloc {}

// Wrap widgets in MaterialApp for theme:
Widget buildTestWidget(Widget child, {required SignInBloc bloc}) {
  return MaterialApp(
    home: BlocProvider<SignInBloc>.value(
      value: bloc,
      child: child,
    ),
  );
}

// Test naming: 'should {behavior} when {condition}'
// Use whenListen/when for stubbing BLoC state
// Test file placement: test/features/auth/presentation/...
```

**Example BLoC test pattern:**
```dart
blocTest<SignInBloc, SignInState>(
  'emits [SignInLoadInProgress, SignInMagicLinkSent] when SignUpRequested succeeds',
  build: () {
    when(() => mockSignUpUseCase(any())).thenAnswer(
      (_) async => const Right(unit),
    );
    return signInBloc;
  },
  act: (bloc) => bloc.add(const SignUpRequested(email: 'test@example.com')),
  expect: () => [
    const SignInState.loadInProgress(),
    const SignInState.magicLinkSent(email: 'test@example.com'),
  ],
);
```

**9. Use Case Params (ACTUAL Signatures — Reference):**

- `SignUpWithEmailParams({required String email})` — freezed
- `SignInWithEmailParams({required String email})` — freezed 
- `VerifyMagicLinkParams({required String email, required String token})` — freezed
- `CreateOrganizationParams({required String name, required String userId})` — freezed (**NO slug param — slug is auto-generated internally**)
- `SendInvitationParams({required String email, required String organizationId, required UserRole role, required String invitedByUserId})` — freezed
- `UpdateUserRoleParams({required String targetUserId, required UserRole newRole, required String requestingUserId})` — freezed (**has `targetUserId` + `requestingUserId`, NOT just `userId`**)
- `RemoveOrganizationMemberParams({required String targetUserId, required String requestingUserId})` — freezed (**has `targetUserId` + `requestingUserId`, NOT `userId` + `organizationId`**)

**⚠️ CRITICAL: `CreateOrganizationParams` does NOT have a `slug` field. The slug is generated internally by `CreateOrganizationUseCase.generateSlug()`. The UI preview of the slug should call this static method directly.**

**⚠️ CRITICAL: Both `UpdateUserRoleParams` and `RemoveOrganizationMemberParams` require `requestingUserId` (the current user's ID from AuthenticationBloc state) AND `targetUserId` (the member being modified). The use cases internally verify the requesting user is Owner.**

**10. RBAC Permissions for UI Actions (Reuse `RbacPermissionService`):**

```dart
// RbacPermissionService is a @lazySingleton, injected via getIt
// It uses INSTANCE methods, NOT static methods:
final rbac = getIt<RbacPermissionService>();

// Check permissions:
final canInvite = rbac.canPerform(currentUser.role, Permission.sendInvitations);
final canChangeRoles = rbac.canPerform(currentUser.role, Permission.changeUserRoles);
final canManageMembers = rbac.canPerform(currentUser.role, Permission.manageTeamMembers);
final canManageOrg = rbac.canPerform(currentUser.role, Permission.manageOrganization);

// Permission enum values (from permission.dart):
// Permission.sendInvitations, Permission.changeUserRoles,
// Permission.manageTeamMembers, Permission.manageOrganization, etc.
```

**⚠️ CRITICAL: `SendInvitationUseCase` already enforces that ONLY Owner role can send invitations (line 68 of send_invitation_use_case.dart). The UI should still check `rbac.canPerform()` to conditionally show/hide the invite button, but the backend enforces it too.**

### Project Structure Notes

- All new files go under `lib/features/auth/presentation/` — aligns with Clean Architecture
- `settings_page.dart` is at `lib/features/settings/presentation/pages/settings_page.dart` — modify in-place
- Route definitions go in `lib/core/router/routes.dart` for typed routes
- `app_router.dart` is at `lib/core/router/app_router.dart` for router config updates
- `navigation_items.dart` is at `lib/core/router/navigation_items.dart` — add Organization nav item
- `auth.dart` barrel file is at `lib/features/auth/auth.dart`

**Exact barrel file exports to ADD (append to `// Presentation - BLoC` section in `auth.dart`):**
```dart
// Presentation - BLoC (EXISTING — keep these)
export 'presentation/bloc/authentication_bloc.dart';
export 'presentation/bloc/authentication_event.dart';
export 'presentation/bloc/authentication_state.dart';
// Presentation - BLoC (NEW — add in alphabetical order)
export 'presentation/bloc/organization_management_bloc.dart';
export 'presentation/bloc/organization_management_event.dart';
export 'presentation/bloc/organization_management_state.dart';
export 'presentation/bloc/sign_in_bloc.dart';
export 'presentation/bloc/sign_in_event.dart';
export 'presentation/bloc/sign_in_state.dart';
// Presentation - Pages (NEW)
export 'presentation/pages/auth_page.dart';
export 'presentation/pages/magic_link_callback_page.dart';
export 'presentation/pages/organization_dashboard_page.dart';
export 'presentation/pages/organization_setup_page.dart';
// Presentation - Widgets (NEW)
export 'presentation/widgets/invite_member_dialog.dart';
```

### Anti-Patterns to Avoid

- **DO NOT create new use cases** — all domain logic exists; BLoCs call use cases directly
- **DO NOT modify `AuthenticationBloc`** — it's a singleton managing global auth state
- **DO NOT call `MigrateDemoDataUseCase` from UI** — `CreateOrganizationUseCase` calls it internally
- **DO NOT create a `slug` field on `OrganizationCreationRequested` event** — only pass `name` + `userId`
- **DO NOT put `OrganizationSetupRoute` inside shell routes** — user has no org yet, no nav shell
- **DO NOT use static methods on `RbacPermissionService`** — it uses instance method `canPerform(role, permission)`
- **DO NOT hardcode role checks** like `if (role == UserRole.owner)` in UI — use `rbac.canPerform()` for consistency
- **DO NOT create `UserRepository` implementations** — they already exist with full CRUD + org queries

### References

- [Source: epics.md#Story-2.11] — Story AC and user story statement
- [Source: architecture.md#Frontend-Architecture] — BLoC scoping, theming, forms
- [Source: architecture.md#Implementation-Patterns] — Naming conventions, file patterns
- [Source: architecture.md#Core-Architectural-Decisions] — Auth method, RBAC, demo mode
- [Source: ux-design-specification.md#Design-System-Foundation] — Material Design 3, Navy/Gold colors, Inter font
- [Source: ux-design-specification.md#Anti-Patterns-to-Avoid] — No modal overload, simple role management
- [Source: 2-10-demo-to-production-migration.md] — Demo migration already integrated into CreateOrganizationUseCase
- [Source: app_router.dart] — Existing redirect guard and route registration patterns
- [Source: authentication_bloc.dart] — Global auth BLoC singleton with state stream
- [Source: shell_routes.dart] — AppShellScaffold responsive navigation pattern
- [Source: home_page.dart] — Existing Sign In TODO stub to replace (line 51-55)

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
